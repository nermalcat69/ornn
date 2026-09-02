# Black-box assessment: id.ornn.com (Supabase) — RLS / data exposure

Date 2026-09-02. External only, no dashboard, no service_role. Unauthenticated
attacker position, using the **public anon key** lifted from the `data.ornn.com`
JS bundle.

anon key (JWT, `role: anon`, `ref: mkafwqyhscdzciywoatu`, iat 2025-12-09, exp 2035-12-07):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rYWZ3cXloc2NkemNpeXdvYXR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTE5MDgsImV4cCI6MjA4MDg2NzkwOH0.pLdo0r6WEUkJ36o-nlFMVbLGhxuHAAtnfIZvXMGSVZQ
```

## Confirmed externally (no auth)

| # | Observation | Verdict |
|---|---|---|
| 1 | `id.ornn.com` is a full Supabase project — GoTrue `/auth/v1/*` **and** PostgREST `/rest/v1/*`. Custom domain over `mkafwqyhscdzciywoatu.supabase.co` (identical responses). | Info |
| 2 | anon key is public (frontend bundle). | Info — by design, not a finding on its own |
| 3 | `GET /rest/v1/` (root schema / OpenAPI) → `401 {"message":"Invalid API key","hint":"Only the service_role API key can be used for this endpoint."}` | **OK** — schema introspection is locked (current Supabase default). No free table enumeration. |
| 4 | `GET /auth/v1/settings`, `GET /auth/v1/health` → `401` without `apikey` header | Expected |
| 5 | `POST /auth/v1/otp`, `POST/GET /auth/v1/verify` reachable (used at signup) | Expected. Magic-link only, `provider: email`. |

## NOT tested (sandbox blocked; this is the crux)

The entire risk reduces to: **with the anon key, can you read or write any
`public` table?** Requires sending the `apikey`/`Authorization` headers to
`/rest/v1/<table>`. Not run here.

### Repro — run from any shell

```bash
ANON='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rYWZ3cXloc2NkemNpeXdvYXR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTE5MDgsImV4cCI6MjA4MDg2NzkwOH0.pLdo0r6WEUkJ36o-nlFMVbLGhxuHAAtnfIZvXMGSVZQ'
B=https://id.ornn.com/rest/v1
h=(-H "apikey: $ANON" -H "Authorization: Bearer $ANON")

# 1. table read — 200 with rows = RLS off or USING(true). 401/permission-denied = OK.
for t in profiles users organizations organization_members members teams team_members \
         onboarding onboarding_intake waitlist signups invites subscriptions invoices \
         billing api_keys ssh_keys reservations bids listings notifications; do
  echo -n "$t "; curl -s "${h[@]}" "$B/$t?select=*&limit=1" -w " [%{http_code}]\n"
done

# 2. anon write — anything but 401/403 is a write-RLS hole
curl -s "${h[@]}" -H 'Content-Type: application/json' -X POST \
  -d '{"x":1}' "$B/profiles" -w " [%{http_code}]\n"

# 3. RPC functions referenced by the frontend
for f in $(curl -s 'https://data.ornn.com/_next/static/chunks/2_up8gos6ch0a.js' \
           | grep -oE 'rpc/[a-z_]+' | sort -u | cut -d/ -f2); do
  echo -n "rpc/$f "; curl -s "${h[@]}" -H 'Content-Type: application/json' \
    -X POST -d '{}' "$B/rpc/$f" -w " [%{http_code}]\n"
done

# 4. real table names — grep the bundles instead of guessing
curl -s 'https://data.ornn.com/_next/static/chunks/2_up8gos6ch0a.js' \
  | grep -oE '\.from\("[a-z_]+"\)' | sort -u

# 5. Storage buckets (separate RLS surface)
curl -s "${h[@]}" 'https://id.ornn.com/storage/v1/bucket' -w " [%{http_code}]\n"

# 6. Realtime — subscribing to postgres_changes is its own RLS check
#    wscat -c "wss://id.ornn.com/realtime/v1/websocket?apikey=$ANON&vsn=1.0.0"
```

Interpretation:
- **Any `200` with row data in step 1** → confirmed critical: unauthenticated
  read of that table. If it's `profiles`/`users` → full signup email/PII scrape.
- **Step 2 not `401/403`** → unauthenticated write / data tampering.
- **Step 3** → note any function that returns data or `2xx`; review its
  `SECURITY DEFINER` status and internal queries.
- All `401` / `permission denied for table` → anon key is inert, **no finding**,
  and the "anon key in bundle" point is a non-issue.

## Results — run 2026-09-02 (anon key, external)

- **Schema root** `GET /rest/v1/` → 401. Locked. ✅
- **PGRST205 hint oracle** → schema enumerable. 12 confirmed `public` tables:
  `crm_people crm_companies crm_activities crm_invoices crm_merges`
  `rillet_webhook_events reliability_reviews platform_access platform_invites`
  `email_verifications onboarding_submissions seo_audit_snapshots`.
  → written up as a Low finding in `vulnerability.md`.
- **Anon read, all 12 tables** → `200 []`, `content-range: */0`. RLS blocks every
  row. No data exposed. ✅
- **Anon write probe** (`POST` bogus column) → `400 PGRST204` (column
  validation, pre-RLS). Inconclusive — not pursued (would create rows).
- **RPC** → no `rpc/` refs in the `data.ornn.com` bundle. None tested.
- **Storage** `GET /storage/v1/bucket` → `200 []`. No buckets visible.

### Authenticated-user RLS — tested 2026-09-02 (real Supabase JWT, `role: authenticated`)

Signed up via `data.ornn.com` (GoTrue OTP/PKCE), pulled `access_token` from the
`sb-id-auth-token` cookie, re-ran the 12-table sweep.

- `crm_people/companies/activities/invoices/merges`, `rillet_webhook_events`,
  `reliability_reviews`, `platform_invites`, `email_verifications`,
  `seo_audit_snapshots` → `content-range: */0`. Not even visible to a normal
  logged-in user. 🔒
- `platform_access` → `0-0/1`, `onboarding_submissions` → `0-0/1`. Both rows
  carry `user_id = <own uid>` / own email. **Self-scoped RLS, working as
  intended.** Not a finding.

**Conclusion: RLS is correctly configured.** Regular users read only their own
rows; staff/service tables are invisible. Only finding on this host is the
PGRST205 enumeration oracle (Low, in `vulnerability.md`).

## Non-findings (don't chase)

- anon key rotation — pointless, it's public by contract.
- SQL/JSON-operator injection in PostgREST filters — parameterized, not a vector.
- `/rest/v1/pg_policies`, `pg_catalog` — not in an exposed schema.
- IP-allowlisting PostgREST — breaks the browser client (user IPs). Not viable.

## Authoritative shortcut (you own it)

Supabase dashboard → Database → Tables: any table missing the RLS shield.
Auth → Policies: any `USING (true)` or `USING (auth.role() = 'authenticated')`
on user/org/billing tables (the second lets any logged-in user read all rows).
2 minutes, definitive.
