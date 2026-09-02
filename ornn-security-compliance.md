# Ornn — Security & Compliance: Posture & Backlog

**Purpose:** internal orientation for a security engineer joining Ornn. What the security
posture looks like today (from public docs only), and what needs building. This is an
*outside-in* read — scraped from `data.ornn.com` and `docs.ornn.com` `llms-full.txt` on
2026-09-02 ([ornn-docs-scraped.md](ornn-docs-scraped.md)) — so "Not documented" means
"not visible externally," not necessarily "doesn't exist." First job on day one:
replace every "Not documented" with a real answer from internal systems.

Two products in scope:
- **Ornn Data** (`data.ornn.com`) — market-data REST API + MCP, tiered by API key.
- **Ornn Compute** (`docs.ornn.com`) — GPU reservation marketplace, bare-metal/VM/K8s, CLI.

## 1. Identity & Authentication

| Area | Ornn Data | Ornn Compute |
| --- | --- | --- |
| User sign-in | Passwordless magic link (default), Google / GitHub / Microsoft OAuth. All methods resolve to one account. | Same web authorization layer; CLI (`ornn login`) and browser share one session. |
| Programmatic auth | API key as `Authorization: Bearer`. Key prefixes encode plan/grain: `sk_prem_` (Premium, daily only), `sk_live_` (Full, org-grained). | CLI device-authorization flow; approved session stored at `~/.config/ornn/auth.json`. K8s access via short-lived, namespace-scoped kubeconfig token. |
| Sessions | Persist across browser restarts until sign-out or expiry. Email change signs out other sessions and revokes tokens. | Same. `ornn logout` clears local CLI session. |
| MFA / SSO / SCIM | Not visible externally. | Not visible externally. |
| Key management | Keys created/revoked in dashboard; revoked key → `401 "API key is inactive"`. Rotation is manual. | SSH keys added/rotated per reservation; WireGuard peer keys rotated via Network tab. |

**Concerns to verify internally:** MFA enforcement (staff + customers), enterprise SSO/SAML,
API-key entropy/hashing at rest, key expiry & rotation, whether magic-link + OAuth on one
account allows account-takeover pivots.

## 2. Authorization & Tenancy

- **Org = tenant.** Every account belongs to one auto-created organization sharing reservations, inventory, and billing.
- **Two roles only:** `admin` (everything that spends money — bids, checkout, resale, invoice payment — *plus* member management) and `member` (read + non-financial: browse, configure access mode, manage SSH keys, read billing). At least one admin always required.
- No custom roles, no per-resource ACLs. `admin` conflates spend authority with user administration — worth splitting.
- **Compute tenant isolation:**
  - K8s namespace-scoped tokens; cluster-wide reads return `Forbidden` by design.
  - Admission policy `ornn-tenant-security-baseline` rejects privileged containers, `hostPID/hostIPC/hostNetwork`, `hostPath` volumes at schedule time. Currently rolling out warn→enforce — confirm it's hard-deny everywhere.
  - Bare-metal `hard reset` wipes tenant data (user, home, keys, `/tmp`, `/var/tmp`, `/dev/shm`) before returning host.
  - Host firewall opens DCGM exporter (`9400/tcp`) source-restricted to Ornn's metrics collector.
- **Data API tiering** enforced 3 ways: REST by key prefix, MCP by account grant, website by live platform tier. Premium requesting hourly grain is *silently downgraded* to daily rather than denied (except hourly-only routes → `403`). Verify the prefix check can't be bypassed and prefixes aren't guessable/forgeable.

## 3. Data Protection

| Control | Status (external view) |
| --- | --- |
| Transport encryption | HTTPS on all documented endpoints; kubeconfig over TLS. TLS-version/cipher policy not visible. |
| Encryption at rest | Not visible — confirm for DB, compute storage volumes, object storage, backups. |
| Data residency | Storage instances region-scoped (e.g. Oregon); no residency commitment documented. |
| Tenant data on shared hosts | Cleared on hard reset / relaunch. Sanitization *between* reservations on the same bare-metal host needs confirming (disk wipe, NVRAM, GPU memory). |
| Secrets handling | Docs tell integrators to keep `Authorization: Bearer` server-side. Internal secret storage (KMS/vault) not visible. |
| Customer object storage | S3-compatible sources registered with scoped credentials; reservation-scoped bucket/prefix placement. |

## 4. Personal & Financial Data

- **Collected:** name, email, optional job role; company name, billing name/email, billing address, invoice email, optional PO number and CC recipient.
- **Payments:** **Stripe** (card intent + ACH/US bank via microdeposits) — Stripe-hosted pages, so raw PAN/bank numbers should never touch Ornn systems (confirm). **Full**-plan billing via **Rillet**.
- **Known sub-processors:** Stripe, Rillet. Need the complete list (cloud/colo, email, analytics, error tracking, support).
- **Account deletion:** manual via Support ("Danger Zone"). No self-serve delete, no stated erasure SLA — a GDPR/CCPA gap.

## 5. Availability & Operations

- `/health` endpoint (public, unauthenticated).
- Rate limits: public/catalog routes **60 req/min/IP** — limiter runs *before* auth, so a valid key does **not** raise the limit; `POST /api/chat` **20 msg/min/key** (spends model tokens).
- Compute observability: telemetry/logs/metrics feeds, DCGM GPU health, reservation Observability tab.
- SLA/uptime: reservation pages currently render **placeholder** SLA/uptime — Ornn stopped estimating from wall-clock, real telemetry pending. No contractual SLA in public docs.
- Real-time GPU price route under maintenance (`404` for all callers).

**To confirm internally:** WAF/DDoS protection, backup cadence + restore testing, DR plan / RTO / RPO, on-call & incident-response runbook, status page.

## 6. Compliance Posture (external view)

| Item | Status |
| --- | --- |
| SOC 2 / ISO 27001 | Not mentioned anywhere public. |
| GDPR / CCPA | No public privacy policy, DPA, or sub-processor page found. |
| HIPAA / PCI-DSS | Not claimed. PCI scope minimized by Stripe-hosted capture (likely SAQ A). |
| Audit logging | No customer-facing audit log; internal audit trail coverage unknown. |
| Pen testing / vuln disclosure / bug bounty | Nothing published (no `security.txt`, no `/security`). |

## 7. Day-1 → Quarter-1 Backlog

Rough priority order for the security function:

1. **Inventory the truth.** Fill every "Not visible" above from internal systems: encryption at rest, secret management, MFA status, sub-processor list, backup/DR, logging coverage.
2. **MFA everywhere.** Enforce for staff (IdP + infra + CI + cloud consoles) first, then ship customer MFA + enterprise SSO/SAML/SCIM.
3. **API-key hardening.** Confirm keys are hashed at rest with per-key salt; add rotation, optional expiry, per-key (not just per-IP) rate limiting, and scoping beyond the plan prefix.
4. **RBAC split.** Separate "spends money" from "manages users"; add a read-only/billing-only role. Consider per-reservation access grants.
5. **Tenant-isolation assurance.** Verify `ornn-tenant-security-baseline` is hard-deny in all clusters; test cross-tenant escape on shared bare metal (disk, GPU VRAM, BMC/NVRAM, network); document the reprovisioning wipe.
6. **Logging & detection.** Centralize auth, admin, billing, and infra logs; ship a customer-facing audit log; define alerting for privilege changes, key creation, failed-auth spikes, tenant-policy violations.
7. **Compliance program.** Scope and start **SOC 2 Type II** (or **ISO 27001**); pick an auditor; stand up policies, risk register, vendor review, access reviews, change management.
8. **Privacy program.** Publish a Privacy Policy + DPA + sub-processor list; build DSAR + deletion workflows with an SLA; add SCCs for EU/UK transfers.
9. **External security surface.** Publish `security.txt` / vuln-disclosure policy; schedule an annual third-party pen test; consider a bug bounty.
10. **AppSec basics.** SAST/DAST/dependency scanning + secret scanning in CI; threat-model the tiering enforcement, the checkout/Stripe flow, the CLI device-auth flow, and MCP tool exposure.

## 8. Certifications & Standards — Reference

Context for the compliance and privacy items in §7. For each framework: what it is, what a
customer expects when they ask for it, what Ornn would be promising by holding it, and what
pursuing it concretely looks like here.

Each subsection below follows the same shape: **what the customer expects** (the buyer's
side of the deal), **what the company promises** (the commitment Ornn takes on by holding
the cert), and **Ornn example** (what pursuing it concretely looks like here, assuming it's
on the future roadmap).

---

### SOC 2 (Type I and Type II)

**What it is.** A report produced by a licensed CPA firm attesting that a service
organization's controls meet the AICPA **Trust Services Criteria** (Security, plus optionally
Availability, Confidentiality, Processing Integrity, Privacy — see the table further down).
It is an *attestation*, not a pass/fail certificate: the auditor describes the controls and
gives an opinion.

- **Type I** — controls are *suitably designed* at a single point in time. Fast (a few
  months), cheaper, but a weak signal: it says nothing about whether the controls actually
  operated. Usually a stepping stone.
- **Type II** — controls were *designed and operating effectively* across an observation
  window (typically 3–12 months; 6 or 12 is standard). This is what enterprise buyers mean
  when they "need your SOC 2."

**What the customer expects.**
- A current Type II report (dated within the last 12 months) delivered under NDA, plus a
  *bridge letter* / *gap letter* covering the period between the report's end date and today.
- Scope that actually includes the product they're buying — the report names the systems,
  and buyers check that the compute platform and the data API are in it, not just the
  marketing website.
- A clean opinion, or if there are exceptions (findings), a management response explaining
  remediation.
- The right criteria in scope: infra/hosting buyers expect **Security + Availability +
  Confidentiality** at minimum.
- Evidence the report is real and continuous year over year, not a one-off.

**What the company promises by holding it.**
- That a defined set of controls (access control, change management, incident response,
  vendor management, encryption, monitoring, onboarding/offboarding, risk assessment, etc.)
  exists, is written down, and is followed — every time, not just when convenient.
- That an independent third party checked sampled evidence across the whole period and
  agreed.
- To keep doing it: the observation windows have to be continuous, so once you start you're
  committing to an annual cycle indefinitely.
- To run the program: named control owners, a risk register reviewed at least annually,
  periodic access reviews, tracked security-awareness training, a formal SDLC.

**Ornn example (future roadmap).**
1. **Readiness (months 0–3):** pick an auditor and a compliance-automation platform
   (Vanta / Drata / Secureframe). Define scope: `data.ornn.com` API + MCP, the Compute
   control plane, the reservation/checkout flow, the bare-metal/K8s fleet, and the
   supporting cloud accounts. Write the ~15 core policies. Close the obvious gaps from
   §7 — MFA everywhere, centralized logging, encryption-at-rest confirmed, formal
   access reviews, an incident-response runbook.
2. **Type I (month 3–4):** point-in-time report to hand to the first enterprise prospects
   who are blocking on *something*.
3. **Type II observation (months 4–10):** 6-month window with the automation platform
   collecting evidence continuously (MFA state, CI checks, access-review completion,
   vuln-scan cadence, `ornn-tenant-security-baseline` enforcement logs).
4. **Report issued (~month 11).** Then repeat annually with a 12-month window.
- Ornn-specific control stories the auditor will want: how tenant isolation is enforced
  and tested on shared GPU hosts; how the `admin`/`member` model and the API-key prefix
  tiering gate access; how the Stripe/Rillet billing boundary keeps cardholder data out;
  how bare-metal reprovisioning wipes tenant data.

---

### SOC 3

**What it is.** A trimmed, general-use version of a SOC 2 Type II — same audit, but the
report is a short public summary with the detailed control descriptions and test results
removed.

**What the customer expects.** To download it from the website or trust page without signing
an NDA, and get enough assurance to clear a lightweight vendor review.

**What the company promises.** The same underlying controls as the SOC 2 it's derived from —
nothing extra. It's a marketing/self-serve artifact.

**Ornn example.** Once the SOC 2 Type II exists, ask the auditor to also issue the SOC 3
(marginal cost). Publish it at `ornn.com/security` alongside the `security.txt` and
sub-processor list so smaller customers and design partners can self-serve.

---

### ISO/IEC 27001

**What it is.** An international standard for an **Information Security Management System
(ISMS)** — the management *process* for security, not a fixed control checklist. A recognized
certification body audits it and issues a certificate valid for three years, with lighter
surveillance audits in years 2 and 3, then recertification. Annex A lists 93 reference
controls (2022 revision); you document applicability in a **Statement of Applicability (SoA)**.

**What the customer expects.**
- A valid certificate naming the certification body, the scope statement, and the expiry
  date. Buyers verify it on the certification body's registry.
- Scope that covers the products and the org units that run them.
- Often accepted *instead of* SOC 2 outside the US; some enterprises want both.
- The SoA and sometimes the latest surveillance-audit summary on request.

**What the company promises.**
- To run security as a managed system: leadership commitment, security objectives,
  a risk-assessment methodology applied and reviewed, internal audits, management reviews,
  corrective-action tracking, continual improvement.
- To maintain the whole documentation set (ISMS scope, risk treatment plan, SoA, policies)
  and keep it current, not frozen at certification.
- To pass surveillance audits every year or lose the certificate.

**What's different from SOC 2.** SOC 2 gives the customer a detailed report of *what your
controls are and how they tested*. ISO 27001 gives a *certificate* saying "an accredited
body confirms this company runs a conforming ISMS" — less detail to the reader, more emphasis
on process maturity. Evidence overlaps ~60–80%, so companies often do both off one program.

**Ornn example (future roadmap).** Run it on the same automation platform and evidence base
as SOC 2, staggered ~6 months behind. Key deliverables unique to ISO: a written risk
methodology and a populated risk register (assets → threats → treatments), the ISMS scope
document, the SoA justifying each Annex A control as applicable/excluded, and at least one
full internal audit + management review before the stage-2 audit. Natural once EU/UK
compute customers start asking.

---

### ISO/IEC 27017 and 27018

**What they are.** Extensions to 27001, certified as add-ons:
- **27017** — cloud-specific security guidance: shared-responsibility clarity,
  virtual-machine hardening, admin-operations logging, tenant isolation, return/removal of
  assets when a contract ends.
- **27018** — protection of **personally identifiable information** processed in a public
  cloud acting as a processor: consent, transparency, no use of customer PII for the
  provider's own purposes (e.g. advertising), sub-processor disclosure, breach notification.

**What the customer expects.** For a cloud host running their workloads and data, these
answer "what happens to my data on your infrastructure specifically" — VM isolation, deletion
on exit, no secondary use. Privacy-sensitive and EU customers ask for 27018.

**What the company promises.** The 27017 controls (documented shared-responsibility model,
hardened images, tenant-isolation controls, asset return/wipe on termination) and, for
27018, that customer PII is processed only on documented instructions and never mined for
Ornn's own purposes.

**Ornn example.** Add both as extensions when doing 27001 recertification. 27017 maps
directly onto work Ornn already partly does — `ornn-tenant-security-baseline`, the
hard-reset wipe, the namespace-scoped kubeconfig — plus a published shared-responsibility
matrix (what Ornn secures vs. what the tenant secures inside their reservation). 27018 pairs
with the DPA and privacy-program work in §7.

---

### PCI-DSS

**What it is.** The Payment Card Industry Data Security Standard — mandatory for any org
that stores, processes, or transmits cardholder data. Validation level depends on
transaction volume and integration type; the lightest is **SAQ A** (a self-assessment
questionnaire) for merchants who fully outsource card handling to a compliant third party.

**What the customer expects.** Generally *not* something Ornn's customers ask Ornn for —
this is Ornn's obligation to the card networks / its acquiring bank. Customers implicitly
expect their card number is handled safely at checkout.

**What the company promises.** That cardholder data (PAN, CVV, magnetic-stripe data) is
handled per the standard — or, under SAQ A, that it never touches Ornn systems at all
because a compliant processor handles it.

**Ornn example.** Ornn's checkout already redirects card and ACH entry to **Stripe-hosted**
pages (Stripe is PCI Level 1). As long as Ornn never posts raw PANs through its own servers,
logs, or databases, it stays in **SAQ A** scope — the cheapest posture. The security team's
job here is *guarding that boundary*: no card fields proxied through Ornn, no PAN in logs or
error trackers, annual SAQ A completion, and confirming the frontend loads Stripe's iframe/JS
rather than collecting card data itself.

---

### CSA STAR

**What it is.** Cloud Security Alliance's registry, built on the **Cloud Controls Matrix
(CCM)** and the CAIQ questionnaire.
- **Level 1** — a self-assessment (completed CAIQ) published to the public STAR registry. Free.
- **Level 2** — third-party audit, usually bundled with SOC 2 or ISO 27001 ("STAR
  Attestation" / "STAR Certification").

**What the customer expects.** Cloud-focused buyers check the STAR registry; a published
CAIQ lets them skip sending Ornn their own 300-question spreadsheet.

**What the company promises.** Level 1: that the self-reported answers are accurate. Level 2:
the same as the underlying SOC 2 / ISO audit, mapped to CCM.

**Ornn example.** Fill out the CAIQ during SOC 2 readiness (the questions overlap heavily)
and publish it as **STAR Level 1** — low effort, and it deflects inbound security
questionnaires. Upgrade to Level 2 later by asking the SOC 2 auditor to also map results to
the CCM.

---

### HIPAA

**What it is.** US law governing **Protected Health Information (PHI)**. A cloud host that
touches customer PHI is a **Business Associate** and must sign a **Business Associate
Agreement (BAA)** and implement the HIPAA Security Rule safeguards.

**What the customer expects.** If a customer runs healthcare workloads on Ornn GPUs, they'll
require a signed BAA before putting any PHI on the platform, plus assurances on encryption,
access logging, and breach notification.

**What the company promises.** Via the BAA: to safeguard PHI per the Security Rule, limit use
and disclosure, log access, notify the customer of breaches within defined timeframes, and
return or destroy PHI at contract end.

**Ornn example.** A business decision, not just a security one: does Ornn want healthcare as
a segment? If yes — offer BAAs, ensure encryption at rest + in transit everywhere PHI could
land (compute volumes, object storage, backups), tighten access logging on the control
plane, and document the wipe process. If no — say so explicitly in the AUP and keep the
sales team from signing BAAs ad hoc.

---

### Government regimes (FedRAMP / StateRAMP / IRAP / C5 / ENS)

**What they are.** Sector- and country-specific frameworks: **FedRAMP** (US federal),
**StateRAMP** (US state/local), **IRAP** (Australia), **C5** (Germany), **ENS** (Spain).
FedRAMP in particular is a large, multi-year, expensive lift (dedicated environment,
3PAO assessment, continuous monitoring, an agency sponsor).

**What the customer expects.** Public-sector buyers legally *cannot* use a cloud service
without the relevant authorization. It's a hard gate, not a preference.

**What the company promises.** To operate the authorized system boundary exactly as
documented, with continuous monitoring and monthly reporting to the authorizing body.

**Ornn example.** Defer unless there's concrete public-sector demand with a sponsor. If it
comes, it likely means a separate, isolated Ornn environment (e.g. "Ornn Gov") rather than
retrofitting the commercial platform. Not a near-term roadmap item.

---

### Legal / privacy obligations (contractual + regulatory, not "certifications")

These aren't audited badges — they're commitments Ornn makes directly to customers and
regulators. Enterprise deals stall without them.

| Instrument | What the customer expects | What Ornn commits to | Ornn example |
| --- | --- | --- | --- |
| **Privacy Policy** | A public page saying what personal data is collected, why, how long it's kept, and their rights. | Accuracy — it's legally binding, and collecting data outside what it says is a violation. | Publish one covering the fields in §4 (name, email, role, billing contacts) plus cookies/analytics; keep it in sync with reality. |
| **DPA** | A signed contract making Ornn a *processor* acting only on documented instructions, with security duties, breach notice, sub-processor rules, audit rights, and deletion on termination. | To process customer personal data only as instructed, secure it, flow the same terms to sub-processors, notify on breach, and delete/return on exit. | Draft a standard DPA (with SCCs annexed) that sales can send with every enterprise MSA; map "deletion on termination" to the actual bare-metal wipe + account-deletion flow. |
| **Sub-processor list + change notice** | A public, current list of downstream vendors, plus advance notice (commonly 30 days) before adding one, with a right to object. | To keep the list accurate and not silently add vendors that touch customer data. | Publish: Stripe (payments), Rillet (billing), the cloud/colo providers, email/notification vendor, error tracking, analytics, support tooling. Wire a notify step into vendor onboarding. |
| **SCCs / transfer mechanism** | If they're in the EU/UK, a lawful basis for their data leaving the region (Standard Contractual Clauses + a transfer impact assessment). | To stand behind the SCCs and the safeguards described in the TIA. | Annex the EU + UK SCCs to the DPA; document where personal data actually lives (region-scoped storage helps the story). |
| **GDPR / UK GDPR / CCPA-CPRA** | Working data-subject request handling — access, deletion, portability, opt-out — within statutory deadlines, and **72-hour** regulator breach notification under GDPR. | To honor those rights on time and notify on breach within the deadline. | Replace the manual "delete via Support" path with a tracked DSAR workflow (intake → verify identity → fulfill → log) with an SLA well inside 30 days; add breach-notification steps to the incident runbook. |

### The "rules" — the full criteria set an audit tests against

There's no single hidden rulebook — each framework publishes its criteria. Below is the
actual structure of both, so nothing is hand-waved.

#### SOC 2 — Trust Services Criteria (TSC), 2017 (rev. 2022)

SOC 2 has **five categories**. **Security (the "Common Criteria") is mandatory**; the other
four are opt-in based on what you want to attest. The Common Criteria are built on the
**COSO Internal Control framework** and numbered **CC1–CC9**:

| Ref | Common Criteria area | What it covers | Ornn today (external view) |
| --- | --- | --- | --- |
| **CC1** | Control Environment | Governance, org structure, board/management oversight, integrity & ethics, HR policies, accountability. | Not visible — need org chart, code of conduct, background checks, defined security ownership. |
| **CC2** | Communication & Information | Internal/external comms of security responsibilities, policies published, channels for reporting issues. | Partial — good public product docs; no published security policy or `security.txt`. |
| **CC3** | Risk Assessment | Documented methodology, risks identified & analyzed, fraud risk, change impact on risk. | Not visible — no risk register. |
| **CC4** | Monitoring Activities | Ongoing evaluations, control deficiencies tracked to remediation, internal audit. | Not visible — no evidence of control monitoring. |
| **CC5** | Control Activities | Selecting & developing controls (incl. tech controls) that mitigate risk to acceptable levels. | Partial — controls exist (isolation, admission policy) but not tied to a risk process. |
| **CC6** | Logical & Physical Access | Identity, authentication (**MFA**), authorization/least privilege, provisioning & deprovisioning, credentials, encryption, network security, physical/data-center access, secure disposal of media. | Partial — API-key + OAuth auth, namespace/firewall isolation, hard-reset wipe. Gaps: MFA, at-rest encryption evidence, formal joiner/mover/leaver, data-center attestation (likely via colo provider). |
| **CC7** | System Operations | Vulnerability detection & management, monitoring for anomalies, **incident response** & recovery, security event logging. | Weak — observability feeds exist; no visible vuln-mgmt program, SIEM/alerting, or IR runbook. |
| **CC8** | Change Management | Authorizing, designing, testing, approving, deploying changes to infra, data, software; segregation of dev/prod. | Not visible — need documented SDLC, PR review, CI gates, prod-access controls. |
| **CC9** | Risk Mitigation | Business-disruption risk mitigation, **vendor & business-partner risk management**. | Weak — Stripe/Rillet used; no visible vendor-review process or sub-processor governance. |

Then the **category-specific criteria** (only tested if you put the category in scope):

| Category | Criteria | Covers | Should Ornn scope it? |
| --- | --- | --- | --- |
| **Availability** | **A1.1–A1.3** | Capacity planning & monitoring; environmental protections, backup, and recovery infrastructure; **DR / business-continuity plans tested**. | **Yes** — infra buyers expect it. Biggest gap: no tested DR, no RTO/RPO, placeholder SLAs. |
| **Confidentiality** | **C1.1–C1.2** | Identifying & maintaining confidential information; **disposing of it securely** when no longer needed. | **Yes** — customer datasets/model weights on GPU nodes are the core asset. Have: host wipe. Need: data classification + retention/disposal policy. |
| **Processing Integrity** | **PI1.1–PI1.5** | Definitions/specs of processing; completeness & accuracy of inputs, processing, and outputs; data storage accuracy. | **Optional** — relevant to Ornn Data's index/settlement math and billing accrual. Consider once methodology has reconciliation controls. |
| **Privacy** | **P1–P8** (18 criteria) | Notice & consent (P1–P2); collection (P3); use, retention, disposal (P4); access by data subjects (P5); disclosure to third parties (P6); data quality (P7); monitoring & enforcement / complaint handling (P8). | **Defer** — cover privacy via GDPR/CCPA program + DPA first; add the SOC 2 Privacy category later if customers ask. |

> Note: **Security ≠ the "Security" category.** In SOC 2, "Security" *is* the Common
> Criteria CC1–CC9, always in scope. Availability/Confidentiality/etc. add criteria on top.

#### ISO/IEC 27001:2022 — the two parts

**Part 1 — the management-system clauses (mandatory, these are what's certified):**

| Clause | Requirement |
| --- | --- |
| **4** Context | Scope of the ISMS, interested parties, internal/external issues. |
| **5** Leadership | Top-management commitment, information-security policy, roles & responsibilities. |
| **6** Planning | Risk assessment & treatment methodology, **Statement of Applicability**, security objectives. |
| **7** Support | Resources, competence, awareness, communication, documented information control. |
| **8** Operation | Operating the risk treatment plan; risk assessments at planned intervals & on change. |
| **9** Performance evaluation | Monitoring & measurement, **internal audit**, **management review**. |
| **10** Improvement | Nonconformity & corrective action, continual improvement. |

**Part 2 — Annex A controls (the SoA says which apply). 2022 revision: 93 controls in 4 themes:**

| Theme | Count | Examples relevant to Ornn |
| --- | --- | --- |
| **A.5 Organizational** | 37 | Policies, roles, segregation of duties, supplier/cloud-service security, threat intelligence, incident management, **data classification**, access control, identity management. |
| **A.6 People** | 8 | Screening, terms of employment, awareness training, disciplinary process, remote working, NDAs. |
| **A.7 Physical** | 14 | Data-center/office physical entry, equipment siting, secure disposal/reuse of storage media, clear desk/screen. (Mostly inherited from the colo/cloud provider.) |
| **A.8 Technological** | 34 | Endpoint security, privileged access, **MFA/authentication**, malware protection, **vulnerability management**, **encryption / key management**, network security & segregation, secure development, logging & monitoring, **backup**, data leakage prevention, **secure deletion**. |

New in the 2022 revision and worth flagging for Ornn: **threat intelligence, cloud-services
security, ICT readiness for business continuity, physical security monitoring, config
management, data masking, data-leakage prevention, web filtering, secure coding**.

#### One-line mapping to Ornn's current state

| Area | SOC 2 ref | ISO ref | Ornn status |
| --- | --- | --- | --- |
| MFA / access control | CC6 | A.5.15–18, A.8.2–5 | Gap — no MFA visible |
| Encryption at rest | CC6.1 | A.8.24 | Unknown — confirm |
| Tenant isolation | CC6.1, CC6.6 | A.8.22 | Present — admission policy, namespaces, firewall |
| Secure deletion | CC6.5, C1.2 | A.7.14, A.8.10 | Partial — bare-metal wipe; between-tenant assurance unconfirmed |
| Vuln mgmt / pen test | CC7.1 | A.8.8 | Gap |
| Incident response | CC7.3–7.5 | A.5.24–28 | Gap — no runbook visible |
| Change management | CC8.1 | A.8.25–32 | Unknown |
| Vendor risk | CC9.2 | A.5.19–23 | Gap — no sub-processor governance |
| DR / backup / BCP | A1.2–A1.3 | A.5.29–30, A.8.13–14 | Gap — placeholder SLAs, no tested DR |
| Risk register | CC3 | Clause 6 | Gap |
| Policies & governance | CC1–CC2 | Clause 5, A.5.1 | Gap — greenfield |

#### What to build for each Trust Services Criteria category

Concrete features/controls Ornn needs in place to pass each category. "Common Criteria" ship
regardless; the rest only if that category is in the SOC 2 scope.

**Security — Common Criteria (CC1–CC9), mandatory**

- **CC1 Control Environment:** published infosec policy set (~15 policies), a security owner
  (CISO/lead), org chart with roles, code of conduct signed at onboarding, background checks
  for staff, annual security-awareness training with completion tracking.
- **CC2 Communication:** internal policy portal, `security.txt` + `ornn.com/security` page,
  a vuln-disclosure inbox, defined channel for staff to report incidents, customer comms
  plan for incidents.
- **CC3 Risk Assessment:** written risk methodology, a risk register (assets → threats →
  likelihood/impact → treatment → owner), reviewed at least annually and on major change,
  explicit fraud-risk consideration.
- **CC4 Monitoring:** compliance-automation platform (Vanta/Drata) with continuous control
  checks, quarterly internal control review, findings tracked to closure with due dates.
- **CC5 Control Activities:** each risk mapped to a specific control, control-owner
  assignments, segregation of duties in code deploy and billing.
- **CC6 Logical & Physical Access:**
  - SSO/IdP (Okta/Google) for all staff apps; **MFA enforced** on IdP, cloud consoles,
    VPN, CI, DB, and prod SSH.
  - **Customer MFA** + enterprise SAML/OIDC + SCIM provisioning.
  - RBAC with least privilege; the `admin`/`member` split refined (separate billing-only
    and user-admin roles); break-glass accounts logged.
  - Joiner/mover/leaver automation — access granted from role templates, revoked within
    24 h of offboarding; quarterly access reviews with sign-off.
  - API keys hashed at rest (per-key salt), prefix-scoped, rotatable, optional expiry.
  - **Encryption in transit** (TLS 1.2+ everywhere, HSTS) and **at rest** (DB, volumes,
    object storage, backups) with managed KMS.
  - Network segmentation (prod/corp/CI separated), security groups default-deny, bastion
    for admin access.
  - Data-center physical security inherited from colo/cloud provider — collect their SOC 2.
  - **Secure media disposal** — documented wipe/destroy for decommissioned drives and the
    between-tenant bare-metal reprovision wipe.
- **CC7 System Operations:**
  - Vulnerability management: authenticated infra scanning, container image scanning,
    dependency (SCA) scanning, patch SLAs by severity (e.g. crit 7 d / high 30 d).
  - Centralized logging (auth, admin, API, infra, K8s admission) to a SIEM with ≥1 year
    retention; alerting on privilege change, key creation, failed-auth spikes,
    `ornn-tenant-security-baseline` violations, impossible-travel.
  - Annual third-party **penetration test** + remediation tracking.
  - **Incident-response plan** with severities, on-call rotation, runbooks, tabletop
    exercise annually, post-incident reviews.
  - File-integrity / config-drift monitoring on hosts.
- **CC8 Change Management:** documented SDLC, mandatory PR review, CI gates (tests, SAST,
  secret scan, IaC scan), no direct prod push, IaC (Terraform) for infra changes with
  peer review, change log, rollback plan.
- **CC9 Risk Mitigation:** vendor-risk process (security review + SOC 2 collection before
  onboarding any sub-processor), maintained sub-processor register, business-continuity
  plan, cyber-insurance policy.

**Availability (A1.1–A1.3)** — scope this

- Capacity monitoring + autoscaling thresholds and alerts for the control plane and API;
  GPU-fleet capacity dashboards.
- Redundancy: multi-AZ control plane, load-balanced stateless services, DB replication +
  automated failover.
- **Backups:** automated, encrypted, cross-region, with **documented restore tests** at a
  set cadence; defined **RTO / RPO**.
- **DR plan** with a tested failover runbook and an annual DR exercise.
- Environmental protections at the data centers (power, cooling, fire) — from the provider's
  report.
- Real uptime telemetry feeding a **public status page** and a **contractual SLA** with
  service credits (replaces the current placeholder SLA fields).
- DDoS protection + WAF in front of public endpoints; the existing rate limiters documented
  as availability controls.

**Confidentiality (C1.1–C1.2)** — scope this

- **Data classification policy** (public / internal / confidential / customer-data) and
  handling rules per tier; label datastores accordingly.
- Encryption at rest + in transit for everything classified confidential (customer datasets,
  model weights on GPU nodes, object storage).
- Access restricted to confidential data on need-to-know; DLP on egress paths where
  feasible; no customer data in logs, error trackers, or analytics.
- **Retention + secure disposal** schedule: how long each data type is kept, how it's
  destroyed (crypto-erase, drive wipe, tenant-reprovision wipe), evidence of destruction.
- NDAs with staff and contractors; confidentiality clauses in vendor contracts.

**Processing Integrity (PI1.1–PI1.5)** — optional, for the Data product

- Published, versioned methodology for OTPI / OCPI / settlement and for billing/spend
  accrual (partly done in the docs).
- Input validation and completeness checks on ingested price/volume feeds; alerting on
  missing or anomalous source data.
- Reconciliation controls: index outputs vs. source data; billing invoices vs. metered
  usage; automated variance alerts.
- Idempotent, auditable pipeline runs with reprocessing history; immutable/append-only
  storage for settled series (overlapping windows must return identical values — already a
  documented guarantee, so make it a tested control).
- Error handling that surfaces and queues bad records rather than silently dropping them.
- Change control specifically over calculation logic (extra review, backtest before
  release).

**Privacy (P1–P8)** — defer, cover via GDPR/CCPA + DPA first

- Public **Privacy Policy** matching actual collection (P1 notice); consent capture where
  required, cookie-consent banner (P2).
- Collect only what's needed and document purpose per field (P3).
- Use limited to stated purposes; **retention schedule** for personal data; deletion on
  expiry (P4).
- **DSAR workflow** — identity-verified access/export/correction within statutory deadlines
  (P5).
- Sub-processor disclosure + flow-down of privacy terms; no sale/sharing without basis (P6).
- Data-quality mechanisms — users can view and correct their profile/billing data (P7).
- Privacy complaint-handling process, breach-notification procedure (72 h GDPR), periodic
  privacy control review (P8).

---

**Summary for the incoming security engineer:** the engineering-level controls are reasonable
for the company's stage (tenant isolation, scoped tokens, revocable keys, admission policy).
The whole *program* layer is greenfield — no attestations, no formal policies, no published
privacy/legal framework, no external vuln-disclosure path. Expect to build the compliance
and detection functions close to from scratch while hardening auth and multi-tenancy in parallel.
