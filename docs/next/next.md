# Continuity notes — read this at the start of every session

Last updated: 2026-08-22 (end of session 2 — local-buildable scope complete)

## Where things stand

**Three real, tested, cross-integrated services, all running locally, zero BTP account needed:**

1. **`services/procurement-core`** (CAP/Node.js, port 4004) — Requisition →
   Approval → PO workflow, RBAC, 9/9 tests. Now also has a real **SAP Fiori
   Elements UI** (`srv/service-ui.cds`, zero hand-written frontend code,
   served at `/$fiori-preview/ProcurementService/PurchaseRequisitions`) and
   **publishes a `PurchaseOrderCreated` event** (`srv/lib/events.js`) on
   every `approve()`.
2. **`services/ai-copilot`** (port 4005) — RAG over 5 procurement policy/
   contract documents via Ollama (`all-minilm` embeddings, `qwen2.5:1.5b`
   generation — upgraded from 0.5b after a documented synthesis-quality
   finding), a local Langfuse-shaped tracer (real Langfuse deferred — this
   machine's Docker only has 3.8GB RAM allocated), 11/11 tests (6 unit +
   5 live against real Ollama).
3. **`services/spend-anomaly-detector`** (port 4006) — receives the
   `PurchaseOrderCreated` event via HTTP webhook (stands in for a real Kyma/
   Event Mesh subscription), evaluates 4 deterministic rules, 13/13 tests.
   **Verified live, cross-service, end-to-end**: approving a normal PO
   produces a `NONE`-severity review; approving a $65k PO against a
   HIGH-risk supplier correctly produces `HIGH` severity with all 3
   expected flags.

**16 staged git commits**, clean history, each with a real rationale — keep
this pattern going.

Concept docs written: `01-sap-btp-fundamentals.md`, `03-cap-programming-model.md`.
Reference doc: `docs/references/macos-native-build-toolchain.md` (the broken
CLT headers issue — **the CXXFLAGS/CPPFLAGS workaround in that doc is still
needed for any future native `npm install` on this machine**).

To run everything locally: see each service's README for exact commands.
Quick version — `ollama serve` (if not running) with `all-minilm` and
`qwen2.5:1.5b` pulled, then `npm start` in `ai-copilot` and
`spend-anomaly-detector`, and `cds deploy && cds-serve` in `procurement-core`.

## What's now genuinely blocked on the BTP account

Everything left in the charter's domain coverage map needs a live BTP
subaccount to build *and verify* — writing untested Terraform/Jenkinsfile/
ABAP source now would break this project's whole "verified, not
aspirational" standard, so it wasn't done speculatively:

- **`infra/terraform`** — needs real subaccount/region/entitlements to
  `plan`/`apply` against (syntax-only `validate` is possible without an
  account but wasn't worth doing in isolation from real values).
- **`services/supplier-master-abap`** — ABAP Cloud/RAP has no local runtime
  at all; needs a live BTP ABAP Environment (trial or otherwise) reachable
  from Eclipse+ADT (already installed on this machine).
- **`ci-cd/piper`, `ci-cd/sap-cicd-service`** — Project Piper and the managed
  CI/CD service both need a real Cloud Foundry target to deploy to; `ci-cd/
  github-actions` similarly needs real deployment credentials to be more
  than an unverified YAML file. Note: `cds add pipeline` and `cds add
  github-actions` exist as scaffolding commands in this cds-dk version —
  worth using once there's a real target to point them at, rather than
  hand-writing from scratch.
- **`transport/cloud-transport-management`** — CTMS nodes/routes are BTP
  service configuration, meaningless without real subaccounts to promote
  between.
- **`services/integration-flow`** — Integration Suite's Cloud Integration
  designer is a cloud-only tool; no local iFlow authoring/testing exists.
- **Real Langfuse** (vs. the local tracer shim) and **SAP AI Core/Generative
  AI Hub** (vs. Ollama) — both explicitly deferred, AI Core specifically
  needs BTP free-tier (not the plain trial), see `PROJECT_CHARTER.md`.

## Immediate next steps once account details arrive

1. Get subaccount region + subdomain + entitlements available on the trial.
2. `infra/terraform` first — provisioning the landing zone unblocks
   everything else (real HANA Cloud, real XSUAA, Kyma, ABAP Environment).
3. Deploy `procurement-core` for real (`cds add mta` or `cf-manifest`, then
   `cf push`/`cf deploy`) — swap mocked auth for real XSUAA, verify the
   Fiori preview still works against a real deployed OData service.
4. `services/supplier-master-abap` via Eclipse+ADT against the real ABAP
   Environment, gCTS-connected to this same GitHub repo.
5. Wire up real Piper/GitHub Actions CI/CD against the real CF target.
6. `transport/cloud-transport-management` for Dev→QA→Prod promotion.
7. `services/integration-flow`.
8. Revisit AI layer: real Langfuse (once Docker has more RAM, or accept the
   footprint) and/or SAP AI Core (once free-tier is enabled).

## Standing instructions from the user (carried over, still apply)

- Local-first, real code, real tests — not description/scaffolding without
  running it. Continue this for whatever remains locally buildable.
- Tool setup proactive (verify what's installed before installing more —
  this machine already has the full SAP toolchain).
- Concept docs alongside the code that grounds them, not before.
- README + inline docs carry setup/run instructions.
- Full capstone scope, not a quietly-scaled-down MVP.
- Commit in clear phases/stages throughout.
- No destructive host changes without asking.
- A DevOps-domain-wide project is planned next, after this one ships — not
  started.
- User said: "build the full app and at the end ask me account details" —
  this is that end point for the locally-buildable scope. Everything after
  this genuinely needs the account, not a judgment call to keep deferring.

## Things NOT to do (carried over, still applies)

- Do not reuse `career/03-sap/leverx/projects/demo-phase-3`/`demo-phase-4`
  as a foundation.
- Do not frame this project around any specific interview/interviewer.
