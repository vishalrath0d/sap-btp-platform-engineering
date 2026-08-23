# Continuity notes — read this at the start of every session

Last updated: 2026-08-23 (end of session 7 — local Docker/Compose stack,
CI/CD for all 5 services incl. real Kyma manifests, resume-claim gap-check)

## Where things stand

**5 services, 67/67 tests passing, all 15 concept docs written, full
operations layer written, Terraform restructured to real module/
environment conventions with CI-driven apply and a real verified live
plan run (`9 to add, 0 to change, 0 to destroy`). Every service now runs
locally as a real Docker Compose stack, cross-integrated over an actual
network (not just in-process tests), and every service now has real CI/CD
— the 4 Cloud Foundry-bound services via `cf push`/MTA, the one Kyma-bound
service (`spend-anomaly-detector`) via real BTP Operator + APIRule v2
manifests, plus a `deploy-all.yml` orchestrator sequencing the whole
landscape in dependency order. Nothing deploys automatically anywhere —
every deploy job stays gated (`if: false` + a GitHub Environment, or a
typed confirmation input) pending explicit review, per this project's
account strategy.**

### Session 7 additions (this session)
- `docker-compose.yml` + a `Dockerfile`/`.dockerignore` per service. Real
  bugs found and fixed verifying it live (not guessed): `better-sqlite3`
  needs build tools `node:20-alpine` lacks; `cds-serve` doesn't
  auto-migrate the way `cds watch` does; `npx cds` doesn't exist without
  `@sap/cds-dk`; `destination.js` hardcoded `localhost`, doesn't resolve
  between containers. Verified end to end live: `api-gateway ->
  procurement-core -> {legacy-erp-gateway, spend-anomaly-detector}`, full
  chain, real data.
- CI/CD for the 4 services that didn't have it yet (`procurement-core`
  already did): `ai-copilot`/`api-gateway`/`legacy-erp-gateway` get plain
  `cf push` manifests; `spend-anomaly-detector` gets a real Kyma
  deployment (BTP Operator `ServiceInstance`/`ServiceBinding` for XSUAA,
  an `APIRule` in the current v2 syntax — verified against Kyma's actual
  docs, not the deprecated v1beta1 shape).
- `deploy-all.yml` — one `workflow_dispatch` orchestrating `terraform
  apply` → CF services → the Kyma service in real dependency order.
- README rewritten to match `ai-ml-llm-ops`'s structure: real Mermaid
  architecture + sequence diagrams, a testing/navigation guide, verified
  port map.
- **Resume-claim gap-check** (see `PROJECT_CHARTER.md`'s new "Scope
  expansion (session 7)" section): checked this project against
  Vishal's own SAP-track resume's specific claims. Confirmed via research
  that ABAP Environment and Integration Suite are both trial-provisionable
  on this same subaccount (not a separate specialized trial) — added both
  as candidate entitlements to `infra/terraform`'s `entitlements` module,
  flagged for confirmation against the next live plan. `services/
  supplier-master-abap` and `services/integration-flow` remain genuinely
  gated on GUI-only SAP tooling (Business Application Studio/ADT for RAP,
  Integration Suite's web designer for iFlows) — the concrete
  provisioning-then-authoring sequence is written down there, not just
  "still blocked."

### Services
1. `procurement-core` (17/17) — CAP core workflow + Fiori UI + connectivity sync + Workflow Management design note
2. `ai-copilot` (13/13) — RAG copilot, now with a Document Management Service seam (`document-store.js`)
3. `spend-anomaly-detector` (19/19) — anomaly rules + Feature Flags + Alert Notification + Job Scheduling, all real and tested
4. `legacy-erp-gateway` (2/2) — mock on-prem system
5. **`api-gateway`** (16/16, new this session) — API Management simulation: API keys, rate limiting, API Business Hub-style catalog. Verified live end-to-end (client → gateway → procurement-core → legacy-erp-gateway, full chain, real data). **Found and fixed two real bugs in the process** — an empty-body-forwarding bug in the gateway itself, and a more serious one: an unhandled `fetch()` rejection in `procurement-core/srv/service.js`'s `syncLegacySuppliers` handler that **crashed the entire server process** when the legacy system was unreachable. Both fixed and verified.

### Infrastructure — structure corrected twice this session, now settled

`infra/terraform` went through two real corrections, both from Vishal
directly comparing against his own real `sm-infraforge/langfuse` project
rather than accepting a plausible-looking first draft:

1. **Flat → modules/+environments/, files un-duplicated.** First draft
   wrongly duplicated `main.tf`/`variables.tf`/`outputs.tf`/`provider.tf`/
   `versions.tf` inside each `environments/<env>/` dir. Corrected to ONE
   shared set of these files at `infra/terraform/` root, `environments/
   {dev,qa,prod}/` holding *only* a `terraform.tfvars` each — confirmed
   directly against `sm-infraforge/langfuse`'s real structure (which does
   exactly this) before rebuilding. Modules: `subaccount`, `entitlements`,
   `cloudfoundry-env`, `kyma-env` (both renamed from `-environment` per
   explicit request), `xsuaa`, `role-collections`, `destination`.
2. **`backend "remote"` + `-backend-config` → `cloud {}` + env vars.**
   Vishal actually created the real HCP Terraform workspace
   (`procureiq-dev`, org `vishalrath0d-tf-org`, CLI-Driven Workflow,
   Execution Mode: Local) and hit two real things this surfaced: HCP's UI
   now suggests the `cloud` block over legacy `backend "remote"`, and
   **Local-execution-mode workspaces have no Variables tab at all** —
   confirmed against HashiCorp's own docs. `versions.tf`'s `cloud {}` is
   now deliberately empty; `TF_CLOUD_ORGANIZATION`/`TF_WORKSPACE` env vars
   (set per-job in the GitHub Actions workflows) supply the real values.
   Credentials (`btp_username`/`btp_password`/`xsuaa_xsappname`) reach
   Terraform as `TF_VAR_*` env vars sourced from GitHub Actions secrets
   (`BTP_USERNAME`, `BTP_PASSWORD`, `XSUAA_XSAPPNAME`), not HCP Terraform
   workspace variables — that path doesn't exist for Local execution mode.
   Caught and fixed a real bug this surfaced too: an unset GitHub secret
   resolves to `""`, not `null` — `role_collections`' safety check now
   tests both.

**Full audit done at end of session 6**: re-validated the entire module
tree with **Terraform 1.15.9** (installed via `tfenv`, matching what the
real HCP workspace expects — not just the 1.6.0 used earlier), zero
errors. Grepped the whole repo for stale references to the old structure/
module names/backend approach — found and fixed one (a stale tfvars
comment still mentioning "HCP Terraform workspace variables").

**Real applying still happens via GitHub Actions, not local `apply`**
(`.github/workflows/terraform-plan.yml` on every PR,
`terraform-apply.yml` workflow_dispatch-only with an environment choice
input and a typed confirmation, gated behind per-environment GitHub
Environments). **Setup in progress**: HCP Terraform workspace created and
Execution Mode set to Local ✓. Still needed before `terraform-plan.yml`
can run for real: the 4 GitHub Actions secrets (`TF_API_TOKEN`,
`TF_CLOUD_ORGANIZATION`, `BTP_USERNAME`, `BTP_PASSWORD` — `XSUAA_XSAPPNAME`
deliberately deferred to the two-phase apply's step 2) — Vishal was about
to push the repo to GitHub specifically to set these when this session's
transcript ends.

**Open question from this session, not yet decided**: whether to rename
the repo from `sap-btp-platform-engineering` to something shorter before
the first push (asked, answered — see git history/session transcript for
the reasoning — but confirm the final chosen name here once decided,
since it wasn't resolved by end of session).

### Documentation — the full backlog from session 4's research is done
All 15 concept docs (00-14) written, folding in every finding from the
3-agent research sweep (RA0005/RA0033 architecture citations, real Kyma
APIRule v2 syntax, CALMS, Dynatrace note, ATC/AUnit, SonarQube/BlackDuck,
Cloud Identity Services vs XSUAA, Kyma Connectivity Proxy trap, real
`@sap-ai-sdk/foundation-models`/`cap-llm-plugin` package names, the
NISPG/DPDP/CERT-In design-only note, SAP Activate phase mapping tied to a
genuine Explore-before-Realize design decision). Full operations layer
written (`environments.md`, `sre-practices.md` with 4 runbooks — 2
grounded in real verified behavior, 2 in documented reference-project
bugs — `observability.md`, `fiori-launchpad-administration.md`).

### Future projects — written down, not started
`/Users/vishal/Documents/personal/personal-projects/PORTFOLIO-ROADMAP.md`
— the DevOps-domain-wide project (next after this one ships) and its
candidate sub-projects (Jenkins shared library, Terraform shared library,
SRE/observability, Ansible, AIOps auto-healing pipeline, GitOps, secrets
management, DevSecOps, IDP, FinOps), grounded in real reference material
from `/Users/vishal/Documents/sms-magic/smsmagic-projects/devops/`.

## What's left in the backlog (genuinely small now)

- `services/integration-flow` (Integration Suite iFlow), `services/
  supplier-master-abap` (ABAP Cloud/RAP + gCTS), `transport/cloud-
  transport-management` — reclassified this session from "account-gated"
  to "next in the provisioning queue, then genuinely GUI-tool-gated": all
  three are provisionable on this same trial subaccount (confirmed via
  research, see `PROJECT_CHARTER.md`'s session 7 section), but authoring
  the RAP business object and the iFlow both require SAP's own GUI tooling
  (Business Application Studio/ADT, Integration Suite's web designer) that
  can't be driven headlessly - the concrete step order is written in that
  charter section, starting with the two new candidate entitlements
  already added to `infra/terraform/main.tf`.
- MTX/multitenancy — documented not built, deliberately (see
  `docs/concepts/12-multitenancy-and-saas.md` for why half-building it
  would misrepresent verification not actually done).
- Real Langfuse (vs. `ai-copilot`'s local tracer shim) — still deferred,
  this machine's Docker only has 3.8GB RAM allocated.
- Real SAP AI Core / Generative AI Hub — needs BTP free tier, not trial.

Everything else identified in prior sessions' research has been addressed
(documented, built, or explicitly and reasoned-ly deferred).

## Next steps, in order

1. **HCP Terraform setup** (Vishal's action item) — create the free
   account/workspace, add it to `versions.tf`, add `TF_API_TOKEN` as a
   GitHub secret, add `btp_username`/`btp_password` as HCP Terraform
   workspace variables. Nothing Terraform-related can actually run until
   this exists.
2. Once that's done: `terraform-plan.yml` runs automatically on the next
   PR touching `infra/terraform/**` — review the plan output, especially
   the flagged-as-unverified entitlement `service_name`/`plan_name`
   values and Kyma's `plan_name`.
3. Manually trigger `terraform-apply.yml` only after that review — this
   is the actual "deploy to BTP" step the user has said to hold until
   review is complete.
4. Post-deploy: real XSUAA two-phase apply (`role_collections`), then
   ABAP Cloud/RAP via Eclipse+ADT, then `services/integration-flow`,
   then `transport/cloud-transport-management`.

## Known housekeeping

- `mbt build` and any native npm install still need the CXXFLAGS/CPPFLAGS
  workaround from `docs/references/macos-native-build-toolchain.md`.
- `infra/terraform/environments/dev/.terraform.lock.hcl` IS committed
  (real convention); `.terraform/` cache dirs are not, in any module.

## Things NOT to do (carried over, still applies)

- Do not reuse `career/03-sap/leverx/projects/demo-phase-3`/`demo-phase-4`
  as a foundation for code — fine as a reference for real syntax patterns
  (used extensively across sessions 4-5), never as copied source.
- Do not frame this project around any specific interview/interviewer.
- **Do not run `terraform apply` (local or via the gated workflow),
  `cf push`, or `cf deploy` without an explicit go-ahead** — "build it,
  don't deploy yet, test locally, deploy after review" still stands.
