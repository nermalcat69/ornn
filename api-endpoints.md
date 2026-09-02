# Ornn API Endpoint Enumeration

Date: 2026-09-02. Sources: captured traffic (`network.txt`, `verify.txt`,
`otp-header.txt`, `data.txt`), published docs (`docs.ornn.com`), and light
unauthenticated probing.

## Hosts overview (`subdomains.txt`)

| Host | Role | Notes |
|---|---|---|
| `compute.ornn.com` | Web app (Next.js) + `/v1/*` API proxy | Public app + auth. Proxies `/v1/*` → `api.ornn.com`. |
| `api.ornn.com` | **API gateway** | `GET /health` → `{"ok":true,"service":"ornn-api-gateway"}`. Root 404. CORS-enabled. Google Frontend. |
| `orchestrator.ornn.com` | Backend orchestrator | **Not publicly routable** — every path tried returns `404`, empty body, `server: Google Frontend`. No public API surface found. Likely internal-only / requires host- or mTLS-based routing. |
| `orch.ornn.com`, `staging.orchestrator.ornn.com` | Orchestrator (alias / staging) | Same GCP IP `74.125.196.121` as `orchestrator`. |
| `id.ornn.com` | **Supabase Auth (GoTrue)** | `sb-project-ref: mkafwqyhscdzciywoatu`. `/auth/v1/*`. Needs `apikey` header (401 without). |
| `data.ornn.com` | Market-data app (Next.js on Vercel) | Public `/api/public-index/*`. Auth via `id.ornn.com` (Supabase). |
| `mcp.ornn.com` | MCP server | Base `https://mcp.ornn.com/mcp` (401 unauthenticated). |
| `docs.ornn.com` | Docs (Mintlify) | Static. `llms.txt` index. |
| `fabric.ornn.com` + `*.fabric.ornn.com` | Per-tenant "fabric" app instances | `henryornn-`, `willornn-`, `prathamdave-`, `tyephoenix-`, `shane277-snap-`, `devin-`, `harrisontkeen-` prefixes with `-api` / `-orch` / `-status` suffixes. Next.js, Stripe + PostHog + Sentry in CSP. |
| `pay.ornn.com`, `commerce-staging.ornn.com` | Checkout / commerce | |
| `email.ornn.com`, `smtp/mail/pop/imap.ornn.com` | Mail infra (GoDaddy `92.204.80.x`) | |
| `harvey.ornn.com`, `modal.ornn.com`, `index.ornn.com`, `trust.ornn.com`, `support.ornn.com`, `legal.ornn.com`, `status.ornn.com`, `vpn.ornn.com` | Misc / vendor | `modal`, `index` on GCP; `trust` on Cloudflare. |
| `api.ornnai.com` (different apex) | Public GPU index API | Seen in capture: `GET /api/gpu/{type}/index-history`. `ratelimit-limit: 60; w=60`. |

## Confirmed endpoints

### `compute.ornn.com` — auth & onboarding (`/v1/*`, proxied to `api.ornn.com`)

| Method | Path | Notes |
|---|---|---|
| POST | `/v1/auth/sign-in` | Magic-link request. `application/x-www-form-urlencoded`, `email=`, optional `resend=1`. Returns `303`. **No rate limiting** — see `vulnerability.md`. On `api.ornn.com` directly: `415` without correct content-type. |
| GET | `/v1/auth/callback/google` | OAuth callback. Params: `state`, `code`, `scope`, `iss`, `authuser`, `hd`, `prompt`. |
| GET | `/login/verify?email=` | Web page ("check your inbox"). |
| POST | `/v1/onboarding/intake` | Onboarding form submit. |
| GET | `/v1/organizations/{orgId}/onboarding-booking/slots` | Params: `start`, `end`, `timeZone`. Example orgId seen: `37cc227b-d813-4954-94c2-0fbf32ecefd6`. |
| GET | `/v1/auth/magic-link/verify` | Magic-link consume. |
| POST | `/v1/auth/sign-out` | |
| GET | `/v1/invites` | Pending org invites for the session. |
| GET | `/v1/organizations/{orgId}` | — |
| PATCH | `/v1/organizations/{orgId}` | Update org. |
| GET | `/v1/organizations/{orgId}/members` | **Member list incl. emails.** IDOR-check: try another `orgId`. |
| GET | `/v1/organizations/{orgId}/ssh-keys` | Org SSH public keys. IDOR-check. |
| GET/POST | `/v1/support/threads` | Support tickets. |
| GET | `/v1/support/threads/{threadId}` | Single thread. IDOR-check (UUIDs). |
| — | `/v1/*` (rest) | Reservations/portfolio/billing pages are server-rendered — their data calls didn't surface as XHR. `/v1/reservations` etc. still 404; real paths need SSR interception or the CLI allowlist. |

Captured 2026-09-02 via `record.ts` while logged in as `arjun@graycup.in`, org `37cc227b-d813-4954-94c2-0fbf32ecefd6`.

### `api.ornn.com`

| Method | Path | Notes |
|---|---|---|
| GET | `/health` | `{"ok":true,"service":"ornn-api-gateway"}` |
| POST | `/v1/auth/sign-in` | `415` unauthenticated (wrong content-type) — endpoint exists. |

### `id.ornn.com` — Supabase GoTrue (`/auth/v1/*`)

Requires `apikey` + `Authorization: Bearer <anon-jwt>` headers. Anon key (public, from `data.ornn.com` bundle):
`eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...role":"anon"...` (project ref `mkafwqyhscdzciywoatu`).

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/v1/otp?redirect_to=` | Send magic-link/OTP. Body `{email,...}`. `200`. |
| POST/GET | `/auth/v1/verify` | Confirm token. Sets `sb-*` session cookies + `sb-auth-user-id`. |
| GET | `/auth/v1/settings` | Standard GoTrue (401 w/o apikey). |
| GET | `/auth/v1/health` | Standard GoTrue (401 w/o apikey). |
| — | `/auth/v1/{token,signup,user,logout,recover,resend,sso,callback}` | Standard GoTrue surface — present by default, not individually confirmed here. |

### `data.ornn.com` — public market data (`/api/public-index/*`, no auth)

| Method | Path |
|---|---|
| GET | `/api/public-index/daily-index/all` |
| GET | `/api/public-index/forward-shape` |
| GET | `/api/public-index/gpu-types-free` |
| GET | `/api/public-index/token-types-free` |
| GET | `/api/public-index/otpi` |
| GET | `/api/public-index/gpu/{gpuType}/index-history` (e.g. `H100 SXM`, `H200`, `B200`, `A100 SXM4`, `RTX 5090`) |
| GET | `/api/ticker` |
| GET/POST | `/api/onboarding` |
| POST | `/api/subscribe/premium` |
| POST | `/api/telemetry/pageview` |
| GET | `/auth/callback` (web) |

**Note:** `data.ornn.com` never calls PostgREST (`/rest/v1/`) from the browser —
all DB access goes through its own Next.js `/api/*` routes (server-side, likely
`service_role`). Only `/auth/v1/*` (GoTrue) is called directly against
`id.ornn.com`. This *reduces* but does not remove the RLS surface: `id.ornn.com/rest/v1/`
is still internet-reachable with the public anon key regardless of whether the
app uses it — see `supabase-blackbox-assessment.md`.

### `api.ornnai.com` — public GPU index (separate apex)

| Method | Path | Notes |
|---|---|---|
| GET | `/api/gpu/{gpuType}/index-history` | `ratelimit-limit: 60; w=60`, CORS `https://ornn.com` only. |

### `mcp.ornn.com` — MCP server (`POST /mcp`, authenticated)

Tools exposed (from `docs.ornn.com/mcp-server`): `identity_whoami`, `identity_status`,
`telemetry_latest/tail`, `logs_latest/tail`, `ornn_availability_list/show`, `ornn_buy`,
`ornn_bid_create/list/show/update/withdraw`, `ornn_reservations_list/show/checkout`,
`ornn_access_show/activate/switch`, `ornn_access_push_keys/keys_list/keys_add/keys_status`,
`ornn_nodes_reboot/hard_reset`, `ornn_clusters_*` (list/create/show/credentials/kubeconfig/add_node/remove_node/teardown),
`ornn_cluster_users_list/add/revoke`, `ornn_networks_*` (list/show/create/update/delete/attach/detach),
`ornn_vpn_peers_list/create/delete`, `ornn_storage_volumes_*` / `ornn_storage_deploy` /
`ornn_storage_filesystem_deploy` / `ornn_storage_buckets_*`, `ornn_metrics_snapshot/history`,
`ornn_billing_summary/invoices/showback/open`, `ornn_resale_browse/list/update/delist`,
`ornn_ssh_keys_list/add/delete`, `ornn_api` (allowlisted gateway passthrough).

## CLI → API resources (`docs.ornn.com/cli`, `docs.md`)

API base resolves via `ORNN_API_BASE_URL` → config `apiBaseUrl` → host map
(`compute.ornn.com` → `api.ornn.com`). `ornn api <get|post|patch|put|delete> <allowlisted-path> [--data] [--raw]`
hits allowlisted gateway paths. CLI resource groups implying API endpoints:
`listings` (alias `availability`), `exchange` (alias `bid`), `gpus` (alias `reservations`),
`nodes`, `clusters`, `slurm`, `networks`, `storage volumes`, `storage buckets`,
`keys` / `ssh-keys`, `access`, `billing` (`summary`/`invoices`/`showback`/`open`),
`whoami`, `onboarding`. Exact allowlisted path strings are not published — pull them
from an authenticated `ornn` CLI (`--json`/`--raw`) or the client bundle.

## Gaps / next steps

- `orchestrator.ornn.com` returned nothing on every unauthenticated path. To map it,
  test from an authenticated context or with the internal `Host`/routing the gateway uses.
- Real `api.ornn.com` resource paths need a logged-in session (capture XHR from the
  compute.ornn.com app while navigating reservations/portfolio/network/storage).
- Broad path fuzzing was not run here.
