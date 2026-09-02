# Ornn — tech stack (observed)

Inferred from response headers, JS bundles, subdomains, and captured traffic
(`network.txt`, `subdomains.txt`, `docs.md`). 2026-09-02.

## Three separate products

| Product | Host(s) | Purpose |
|---|---|---|
| **Compute** (the platform) | `compute.ornn.com` + `api.ornn.com` gateway + `orchestrator.ornn.com` | GPU reservation / marketplace / node access |
| **Data** (market data) | `data.ornn.com`, `id.ornn.com` | GPU price index, analytics, premium subscriptions |
| **Marketing site** | `ornn.com`, `www.ornn.com` | Framer site |

## Compute platform

| Layer | Tech | Evidence |
|---|---|---|
| Frontend | **Next.js** (App Router, RSC, Turbopack) | `_next/static`, `_rsc=`, `turbopack-*.js`, `?_rsc=` params |
| Fonts | Neue Montreal (PP Neue Montreal) | `_next/static/media/NeueMontreal_*` |
| Hosting (web + API) | **Google Cloud** — `server: Google Frontend`, `via: 1.1 google` | likely Cloud Run / GKE. IPs `8.232.0.49`, `74.125.196.121` |
| API | Custom **`ornn-api-gateway`** at `api.ornn.com` (`{"ok":true,"service":"ornn-api-gateway"}`); `compute.ornn.com/v1/*` proxies to it | `/health` body; CLI host-map `compute.ornn.com → api.ornn.com` |
| Backend orchestration | `orchestrator.ornn.com` / `orch.ornn.com` (+ staging) — internal, not publicly routed | all paths 404 empty, `server: Google Frontend`, same IP `74.125.196.121` |
| Auth | **Better Auth** (better-auth.com, self-hosted) with magic-link + Google social plugins. Cookies `better-auth.session_token` / `__Secure-better-auth.session_token` (HttpOnly, SameSite=Lax, Secure, 7-day). Routes `/v1/auth/{sign-in,sign-out,magic-link/verify,callback/google}` (`?callbackURL=`). | capture — `better-auth.*` cookies, magic-link plugin verify route |
| CLI | `ornn` (Node, `npm i -g`), `ORNN_API_BASE_URL`, `ornn api <verb> <allowlisted-path>` | `docs.md` |
| MCP server | `mcp.ornn.com/mcp` — ~60 tools, JSON-RPC | `docs.ornn.com/mcp-server` |
| Payments | **Stripe** (Checkout, `js.stripe.com`, `hooks.stripe.com`), `pay.ornn.com`, `commerce-staging.ornn.com` | `fabric.ornn.com` CSP |
| Error tracking | **Sentry** (`o4511513401884672.ingest.us.sentry.io`, org id `4511513401884672`) | baggage headers |
| Analytics | **PostHog** (`us.i.posthog.com`) | CSP, capture |
| Compute nodes | Bare-metal + VM; Ubuntu base image w/ PyTorch; SSH; DCGM exporter (`:9400`); k8s + Slurm options; `ufw`/`firewall-cmd` | `docs.md` |
| Node infra | WireGuard-style VPN (`vpn.ornn.com`, `ornn vpn peers`), public/private networking, GCS buckets (`storage.googleapis.com`) | `docs.md`, CSP |

### Per-tenant "fabric" instances

`*.fabric.ornn.com` — pattern `<tenant>-{api,orch,status}.fabric.ornn.com`
(`henryornn`, `willornn`, `prathamdave`, `tyephoenix`, `shane277-snap`, `devin`,
`harrisontkeen`). Next.js + Stripe + PostHog + Sentry (same CSP as main app).
Looks like isolated per-customer control-plane deployments.

## Data product (`data.ornn.com`)

| Layer | Tech | Evidence |
|---|---|---|
| Frontend + API | **Next.js** (App Router, RSC), `x-powered-by: Next.js` | headers |
| Hosting | **Vercel** (`server: Vercel`, `x-vercel-id`, region `bom1`/`iad1`, deploy `dpl_*`) | headers |
| DB / backend | **Supabase** — project ref `mkafwqyhscdzciywoatu`, custom domain `id.ornn.com` (Postgres + PostgREST `/rest/v1/` + GoTrue `/auth/v1/` + Storage `/storage/v1/`), fronted by Cloudflare + Envoy | `sb-*` headers, `x-envoy-*`, `supabase-ssr/0.12.3` |
| Auth | **Supabase Auth (GoTrue)** — email magic-link / OTP (`supabase-ssr` browser client, PKCE) | `verify.txt`, `otp-header.txt` |
| DB access pattern | Browser → Next.js `/api/*` (server-side, service_role) → Supabase. Frontend does **not** call `/rest/v1/` directly. | capture |
| Fonts | FK Roman Standard, PP Neue Montreal, Paper Mono | `/fonts/*`, `_next/static/media` |
| Bot protection | **hCaptcha** (`hcaptcha.com`, `newassets.hcaptcha.com`) | capture |
| Bot mitigation | **PerimeterX / HUMAN** (`px-cloud.net`, `client.px-cloud.net`, `collector-*.px-cloud.net`) | capture |
| Analytics | **PostHog** (`us.i.posthog.com`, `us-assets.i.posthog.com`), **Google Tag Manager** / Google Ads / DoubleClick | capture |
| Sales/outreach | **Warmly** (`getwarmly.com` — `opps-widget`, `opps-api`) | capture |
| Some interactive visuals | `unicorn.studio`, `cdn.jsdelivr.net` | capture |

## Marketing site (`ornn.com`)

| Layer | Tech |
|---|---|
| Builder / host | **Framer** (`server: Framer/cc760a6`, `framerusercontent.com`, `app.framerstatic.com`, `events.framer.com`) behind CloudFront |
| GPU index API it calls | `api.ornnai.com` (separate apex) — `GET /api/gpu/{type}/index-history`, Express-ish (`ratelimit-*` headers, `server: Google Frontend`) |

## Edge / DNS

- **Cloudflare** in front of `id.ornn.com`, `trust.ornn.com` (`cf-ray`, `__cf_bm`).
- **Google Frontend** in front of `compute`, `api`, `orchestrator`, `fabric`, `data.ornn.com`'s API origin (`api.ornnai.com`).
- **Vercel edge** for `data.ornn.com` app.
- Mail: **GoDaddy** (`92.204.80.x` for `mail/pop/imap/smtp.ornn.com`), plus `email.ornn.com` on AWS (`76.223.17.250`), SPF via `_spfm.ornn.com`.
- Status page: `status.ornn.com` (`76.76.21.164` — likely Vercel/Betteruptime-style).
- `trust.ornn.com` on Cloudflare (likely Vanta/Delve trust portal).

## One-line summary

Next.js everywhere. **Compute** = custom Go/Node API (`ornn-api-gateway`) +
orchestrator on **GCP**, custom magic-link auth, Stripe, Sentry, PostHog, MCP
server, per-tenant `fabric` deployments. **Data** = Next.js on **Vercel** +
**Supabase** (Postgres/GoTrue/Storage) with server-side API routes, hCaptcha +
PerimeterX. Marketing = **Framer**.
