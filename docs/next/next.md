# Continuity notes — read this at the start of every session

Last updated: 2026-08-24 (end of session 11 — **all 5 services deployed
and live on the real BTP trial for the first time**; found and fixed 8
more real, live-only bugs getting there; the previously-unused
Terraform-managed HANA Cloud + XSUAA instances gated off and destroyed;
extensive documentation pass — see below)

### Session 11 — first real end-to-end deploy, 8 more real bugs, docs overhaul

**The headline result**: `gh workflow run deploy -f target=cf` now
succeeds completely — `procurement-core`, `ai-copilot`,
`legacy-erp-gateway`, `spend-anomaly-detector`, `api-gateway`, and the
outbound-URL wiring job all green. All 5 apps are live and reachable
over the public internet right now (see root `README.md`'s "Live on
BTP" section for the real URLs — they may be stopped by BTP's trial
auto-stop policy by the time you read this; that section documents how
to check/restart).

**Every real bug found and fixed to get there, in the order hit** (each
is documented in more depth at its own real location, cross-referenced
below — this is the index):
1. GitHub Actions permissions ceiling blocking the whole `deploy.yml`
   file's validation (a reusable-workflow call is checked statically
   against ALL its `uses:` references, even ones the run never
   touches) — fixed with an explicit `permissions:` block.
2. Reusable-workflow secrets scoping (`cf-deploy.yml` couldn't see
   `secrets.BTP_USERNAME` even though it's a real repo secret — a
   `workflow_call`-triggered workflow only sees secrets it declares).
3. Hardcoded wrong CF org name (`procureiq-dev` doesn't exist; the real,
   SAP-assigned org is `4cbf0c12trial`).
4. Hardcoded wrong CF API endpoint (`api.cf.us10.hana.ondemand.com`
   authenticates fine but can't see this org; the real endpoint has a
   `-001` regional-cell suffix). Both 3 and 4 are documented in
   `infra/terraform/README.md`'s "Known limitations" section.
5. Invalid `cf deploy` flag (`--no-confirm` isn't real; `-f` is).
6. `ai-copilot` crashed on every deploy (0/1 instances) — startup
   eagerly called Ollama (unreachable on CF) and `process.exit(1)`ed
   before ever binding a port. Fixed to degrade gracefully instead
   (`services/ai-copilot/src/server.js`'s `main()`), matching the
   `degraded` status its own `/copilot/health` already reported for
   post-boot checks.
7. **HANA Cloud scoping** — Terraform's `btp_subaccount_service_instance`
   creates a Service-Manager/subaccount-scoped instance, invisible to
   the CF space's `hana`/`hdi-shared` broker (confirmed via `cf curl`
   and the cockpit's own Space → Service Instances view — screenshot
   evidence). Fixed by gating `module.hana_cloud` to `count=0`
   (destroying the orphaned instance) and creating the real database
   via `cf create-service`, correctly CF-space-scoped, in
   `cf-deploy.yml` instead. Full story: `infra/terraform/README.md`'s
   "HANA Cloud" section.
8. **XSUAA duplicate conflict** — Terraform's `module.xsuaa` created a
   second `application`-plan XSUAA instance under the same xsappname as
   `procurement-core`'s own MTA-created one, causing a broker-side NPE
   on every deploy attempt. Fixed by gating `module.xsuaa` to `count=0`
   and reverting `role_collections` to a real two-phase apply (deploy
   first, fetch the live xsappname via `cf create-service-key`, apply
   again). Full story: `infra/terraform/README.md`'s "XSUAA" section.

**Documentation overhaul this session** (per explicit request, covering
several things that had gone stale as the deploy work above landed):
- `docs/operations/networking-and-request-flow.md` (new) — infra- and
  code-level request flow, local vs. deployed, including the real XSUAA
  token flow and HDI container/HANA Cloud relationship diagrams.
- `docs/operations/btp-cockpit-navigation.md` (new) — screen-by-screen
  cockpit navigation guide, grounded in real screens visited this
  session (the HANA/XSUAA "Last Operation Details" screens that
  diagnosed bugs 7-8 above).
- `docs/concepts/15-terraform-vs-cockpit.md` (new) — the general
  Terraform-vs-cockpit concept, linking to the concrete per-module table
  now in `infra/terraform/README.md`.
- `infra/terraform/README.md` — major update: real applied status (was
  "not yet applied"), the corrected XSUAA/HANA Cloud sections above, and
  the new per-module cockpit-equivalent table.
- `docs/operations/observability.md` — updated with real, live evidence
  that every service's `/metrics` endpoint and `cf logs` work against
  the real deployed apps right now, and an honest note that
  Prometheus/Grafana scraping of the deployed apps isn't wired yet
  (local-only for the dashboard layer).
- Root `README.md` — status line, live URLs, updated architecture/
  verified sections. (If reading this before that update lands, treat
  `README.md`'s own content as more current than this summary.)

**Not yet done, worth knowing**: `spend-anomaly-detector` is still
temporarily on CF (its natural home is Kyma, still blocked on SAP's
trial approval from session 10 — see `infra/terraform/README.md`'s
Kyma section, unchanged this session). The rename away from "ProcureIQ"
(a real company's name) was raised and explicitly deferred by the user
("let it be, doesn't matter, focus on other things") — not done, and
not currently planned unless asked again.

### Session 10 — real `terraform apply`, real bugs found and fixed, one genuine blocker hit

**Fixed, all live-verified**: `modules/entitlements` and `modules/role-
collections` are now adaptive (look up what's already granted/exists,
only create what's missing) after a live apply failed on both — trial
accounts pre-grant default entitlements automatically, and XSUAA
auto-creates role collections from `xs-security.json`'s role templates,
so Terraform trying to *create* either was always the wrong operation
regardless of naming. All 5 entitlement `service_name`/`plan_name`
guesses were also corrected to their real values (confirmed via `btp
list accounts/entitlement` and the cockpit's Entitlements catalog) -
`cloudfoundry/trial` not `standard`, `hana/hdi-shared` not
`hana-cloud-trial` (which isn't a real entitlement at all -
`procurement-core/mta.yaml` had the identical wrong name, fixed too),
`abap-trial/shared` not `abap/trial`, `integrationsuite-trial/trial` not
`integration-suite/trial`. `modules/cloudfoundry-env`/`kyma-env`'s
adopt-lookup was also fixed to filter on `state == "OK"`, not just
`environment_type` - it would otherwise have silently adopted a
`CREATION_FAILED` instance as if healthy. `terraform plan` is fully clean
now (adopts everything except the Kyma instance itself).

**The real, current blocker - not fixable from code at all**: this trial
account has **no self-service Kyma provisioning**, confirmed twice over
(two live `terraform apply` `CREATION_FAILED` results, then the identical
failure trying the cockpit's own native "Enable Kyma" wizard directly).
SAP's real docs confirm this is by design - a trial Kyma instance must be
**requested from SAP** (email `kyma@sap.com`, subject `SAP BTP, Kyma
Runtime Trial Request`, with Global Account ID `d6ee969e-4694-46b4-9176-
f571df734c28`, Subaccount ID `e40cb8d7-82ad-4851-a323-12751a62402e`, and
administrator emails) and reviewed "on a case-by-case basis within one
month." See `infra/terraform/modules/kyma-env/main.tf`'s own comment and
`infra/terraform/README.md`'s Known limitations for the full story.
**Request sent** - the email above went out. Everything else (CF, XSUAA,
role collections, all 5 entitlements) is fully live-verified and
completely unaffected by this.

**While waiting, `spend-anomaly-detector` moved to Cloud Foundry
temporarily** - `manifest.yml` added, wired into `cf-deploy.yml`/
`Jenkinsfile.cf` alongside the other four CF services (now five), plus a
new `wire-procurement-core-outbound-urls` step/stage setting
`SPEND_ANOMALY_DETECTOR_URL`/`LEGACY_SUPPLIER_ERP_URL` on the real
deployed `procurement-core-srv` route (closes a related pre-existing gap:
`legacy-erp-gateway`'s URL was never wired for a real CF deploy either,
fixed at the same time). `module.kyma_env` in `infra/terraform` is now
gated behind a `kyma_enabled` variable (default `false`) - the module and
all `k8s/`/Kyma workflow files are completely untouched, just not
instantiated/used right now. **Once SAP approves**: flip `kyma_enabled =
true` in `environments/dev/terraform.tfvars`, apply, then switch
`spend-anomaly-detector`'s real deploy target back to `kyma-deploy.yml` -
nothing else needs to change.

### Session 9 — CI/CD restructuring (direct feedback, not a redesign from scratch)

- **`test.yml` replaces 5 per-service `*-ci.yml` files.** Same real
  change-detection property (a change to one service doesn't re-run every
  other service's tests), one file instead of five - `dorny/paths-filter@v3`
  (a real, standard action) drives a `changes` job, every service's own
  job runs conditionally on its output. Jenkins mirrors this with its own
  real built-in `when { changeset "..." }` directive on `Jenkinsfile.cf`/
  `Jenkinsfile.kyma`'s Test stages - no third-party action needed there.
- **`deploy-all.yml` renamed to `deploy.yml`, `terraform apply` removed
  from it entirely.** Infra provisioning (`infra/terraform/
  terraform-apply.yml`) and app deployment are two different lifecycles -
  infra changes rarely and is applied standalone/manually; app code
  changes on every ship-ready commit. `deploy.yml` now takes a `target`
  input (`all`/`cf`/`kyma`/`piper-cf`) and routes to the right reusable
  workflow instead of always running everything - see that file's own
  header comment for the full terraform-vs-deploy dependency mapping.
- **A real GitHub Actions Piper track added**: `piper-cf-deploy.yml`
  installs the actual Piper Go binary (confirmed real, published on
  `SAP/jenkins-library`'s GitHub releases) and calls `piper mtaBuild`/
  `piper cloudFoundryDeploy` directly - Piper genuinely runs on both
  Jenkins and GitHub Actions, only `project-piper-action` (the old GitHub
  Actions *wrapper*) is deprecated, not Piper itself. Not yet live-verified
  (flagged honestly in `ci-cd/piper/README.md`).
- Real Prometheus + Grafana across all 5 services (see session 8 below),
  and the full ABAP RAP / Integration Suite iFlow / Cloud Transport
  Management backlog filled as real source (see `PROJECT_CHARTER.md`'s
  "Scope expansion (session 8)" section) - both already covered in detail
  there, not re-summarized here.

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

## Idea parked for the end, if there's time (not a commitment)

**Making the CF-bound services deployable to Kyma too (and vice versa) -
genuine runtime swappability, not just the fixed CF-vs-Kyma split each
service has today.** Explicitly *not* doing this now: today's split is
architectural (see the session 9/10 discussion in conversation history -
`spend-anomaly-detector` is event-driven, the other four are synchronous
request/response, which is *why* each sits where it does, not an
arbitrary assignment) and covers both CF and Kyma for real, which was the
actual goal. Making every service swappable between runtimes would mean
building a second deployable shape for each one (buildpack manifests for
`spend-anomaly-detector`, or container images + K8s manifests for the
other four) - real, doable, but a genuinely separate chunk of work with
its own tradeoffs to design (e.g. a synchronous CAP app on Kyma needs its
own Helm chart via `cds add kyma`, not just a Dockerfile), not something
to half-do. Revisit only if there's spare time at the very end - keeping
the current one-natural-runtime-per-service split is the better default
otherwise, not a stopgap.

## Next steps, in order

Infra is applied, all 5 services are deployed and live — this list is
what's actually left, not "get to a first deploy" anymore:

1. **Once SAP approves the pending Kyma trial request** (session 10 —
   still pending, see `infra/terraform/README.md`'s Kyma section): flip
   `kyma_enabled = true` in `environments/dev/terraform.tfvars`,
   re-apply, then switch `spend-anomaly-detector`'s real deploy target
   from `cf-deploy.yml` back to `kyma-deploy.yml`/`piper-kyma-deploy.yml`
   (both already written and untouched, per session 10's notes).
2. ABAP Cloud/RAP via Eclipse+ADT, then `services/integration-flow`,
   then `transport/cloud-transport-management` — the entitlements for
   the first two are already granted and confirmed (session 10); none
   of the three are blocked on anything from this session.
3. Wire real Prometheus/Grafana scraping against the deployed BTP apps
   (or SAP's own Continuous Delivery/Cloud ALM Monitoring) — the
   `/metrics` endpoints are live and correct today, nothing is scraping
   them yet. See `docs/operations/observability.md`.
4. Set up Application Networking (`cf add-network-policy`) for the
   inter-app calls that currently go over public routes — see
   `docs/operations/networking-and-request-flow.md`'s "Known
   limitations" for exactly which calls and why this wasn't done yet.
5. A genuine end-to-end OAuth2/XSUAA token test against the deployed
   `procurement-core` (not just CAP's local mocked auth) — see
   `docs/operations/networking-and-request-flow.md` §3.

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
- **This project is now genuinely live-deployed** — "build it, don't
  deploy yet" no longer applies as a blanket rule; it did its job
  through session 10 and was explicitly superseded by real go-aheads in
  sessions 10-11 (`terraform apply`, `cf push`/`cf deploy` all run for
  real, repeatedly, against the live account). Still confirm before any
  *new* category of real-account action (e.g. a first `terraform
  destroy` of something not already gated to `count=0`, or provisioning
  a genuinely new paid resource) — the standing caution is about
  irreversible/costly actions specifically, not deploying at all anymore.
- Do not rename the project away from "ProcureIQ" unless explicitly
  asked again — raised this session (it's a real company's name),
  explicitly deferred by the user ("let it be, doesn't matter").
