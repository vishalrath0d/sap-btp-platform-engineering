# Project Charter — SAP BTP Platform Engineering

This is the anchor document for the project. Read this first in any new session before touching code — it carries the decisions that would otherwise get re-litigated or forgotten.

## Why this project exists

Vishal is a DevOps engineer (3.5+ yrs, SMS-Magic) switching domains toward SAP. He already holds an **EY-GDS offer** in the SAP space — so, unlike `ai-ml-llm-ops` (which grew out of a live interview gap), this project is **not** built to answer a specific interviewer's question. It exists to:

1. Learn SAP BTP platform engineering hands-on, at production depth — not tutorial depth.
2. Produce a public artifact that showcases that learning across the **whole SAP ecosystem** (BTP, ABAP Cloud, DevOps toolchain, security, integration, AI) the way `ai-ml-llm-ops` showcases the whole AI/ML/LLM Ops ecosystem — same bar: real running services, measured numbers, honest limitations, cross-referenced docs.
3. Serve as this project's sibling: a **DevOps-domain-wide** project is planned next, after this one ships.

**Explicitly not reused**: `career/03-sap/leverx/projects/demo-phase-3` / `demo-phase-4` (the "bookshop" CAP app built for LeverX interview prep) is a toy/scratch artifact and is **not** the foundation here. This repo is built fresh. It's fine to glance at it for "what mtaext/xs-security.json syntax looks like," nothing more — no code, no domain model, no branding carries over.

## Domain: Procurement Intelligence ("ProcureIQ")

Business scenario: **Purchase Requisition → Purchase Order → Supplier → Contract**, extending an S/4HANA-style core via BTP side-by-side extensibility (Clean Core principle — don't modify the core, extend around it).

Why this domain, specifically:
- It's one of the most common *real* SAP BTP extension scenarios in the industry — instantly recognizable to an SAP hiring manager, unlike a generic CRUD demo.
- It naturally motivates every technology this project needs to cover: approval workflows (security/roles), supplier documents (RAG/AI), spend events (Kyma/eventing), legacy supplier feeds (Integration Suite), master data (ABAP Cloud/RAP).
- It supports credible AI use cases without forcing them in: supplier risk scoring, contract-clause Q&A, spend anomaly detection.

## Account strategy

**Start on the plain 90-day BTP trial (no card).** SAP AI Core / AI Launchpad / Generative AI Hub are *not* available on trial — they require BTP free tier (PAYG/CPEA, ~$1 card-verification hold, no expiry, no charges within free quota). Design every AI-touching piece so it works two ways:

- **Trial mode (now)**: RAG retrieval via HANA Cloud Vector Engine (trial-available) + an external LLM call (reuse the multi-provider gateway pattern from `ai-ml-llm-ops` — Ollama local model or a BYO API key), traced via Langfuse.
- **Free-tier mode (later, opt-in)**: same RAG feature, but the LLM call routes through SAP AI Core / Generative AI Hub instead — documented as a clearly-labeled upgrade path, not silently assumed. When Vishal is ready to add the card hold, this becomes a scoped, well-defined follow-on task, not a redesign.

Never block trial-mode functionality on free-tier being enabled. Every doc that touches AI Core must state plainly which mode is described.

## Scope: full capstone

All of the following are in scope for v1 (not a stripped MVP):

- Multi-environment promotion (Dev → QA → Prod) via Cloud Transport Management
- Both Cloud Foundry *and* Kyma runtimes in active use (not just CF)
- ABAP Cloud / RAP module, version-controlled via **gCTS** (and abapGit as the BTP ABAP Environment equivalent)
- Terraform-provisioned landing zone (subaccounts, entitlements, CF org/space, Kyma, role collections) — destroy/rebuild-able, since the trial has a 90-day hard wall
- CI/CD via **Project Piper** (Jenkins — the credible path; the GitHub Actions Piper wrapper is deprecated upstream) *and* a parallel GitHub Actions track *and* the managed SAP Continuous Integration and Delivery service as a no-Jenkins alternative
- AI copilot (RAG + Langfuse tracing) as described above
- Integration Suite iFlow simulating a non-SAP legacy feed
- A thin Fiori/UI5 front end (proves "SAP standards," not just API-only)
- Full docs/concepts layer mirroring `ai-ml-llm-ops`'s depth (see Domain Coverage Map below)

## Scope expansion (session 3 — comprehensiveness gap-check)

After the local-buildable scope (procurement-core, ai-copilot, spend-anomaly-detector) shipped, Vishal compared this project against `ai-ml-llm-ops` and correctly judged it thin by comparison, and asked for a systematic check against SAP's own official Learning Journeys and real job postings rather than a guess. That research (full report kept in session history) produced three buckets:

**BTP-native gaps that clearly belong here** (all added to the coverage map below): Cloud Connector + Destination service connectivity — named as a top objective of SAP's own "Administrating SAP Business Technology Platform" learning journey, and the single starkest gap the project had (zero on-prem-adjacent story despite the domain's own "legacy supplier feed" scenario); SAP Business Application Studio as the standard cloud dev environment; SAP Cloud ALM as the DevOps-journey-mandated monitoring/ITSM-lite layer (explicitly instead of classic Solution Manager, which SAP itself is moving customers off of); multitenant SaaS CAP patterns via `@sap/cds-mtxs` (MTX) — core official CAP documentation territory, currently entirely absent; SAP Alert Notification Service + Job Scheduling Service, wired into the existing `spend-anomaly-detector`; SAP API Management / API Business Hub in front of `procurement-core`; SAP Feature Flags service; SAP Automation Pilot (named directly in real jobs.sap.com DevOps postings); SAP Workflow Management (BPMN-based, distinct from classic ABAP Business Workflow); SAP Document Management Service as the AI copilot's real document store.

**Adjacent-but-defensible additions**: reframing the phased roadmap explicitly in **SAP Activate** terms (Discover/Prepare/Explore-Fit-to-Standard/Realize/Deploy/Run) — this content is now literally embedded in Cloud ALM's own task guidance, and answering "do you understand how SAP projects are delivered" is something a pure-code portfolio otherwise can't demonstrate; a Fiori Launchpad administration note distinguishing "I built the app" from "here's how an admin exposes it via catalogs/spaces/role collections"; a short SoD/GRC-concept note tied to the existing Approval/RBAC model (the concept, not the GRC product suite); a short SAP Digital Access/licensing paragraph in the FinOps doc.

**Explicitly, deliberately out of scope** — see the dedicated section below. Getting this list right matters as much as the additions: padding the project with a different specialization's tools would read as scope confusion, not comprehensiveness.

## Explicitly out of scope (and why)

Mirrors `ai-ml-llm-ops`'s "known limitations" discipline — stating on purpose what this project does *not* cover is itself a signal of domain awareness, and preempts "why didn't you cover X" with an answer instead of a gap.

| Not covered | Why |
|---|---|
| Classic on-prem Basis administration (STMS, SPAM/SAINT, SU01/PFCG, SM37/SM21/ST22/DB02, kernel/support-package upgrades) | A distinct Basis Administrator specialization for on-prem AS ABAP systems — doesn't appear in BTP-developer or DevOps-engineer job postings, only Basis-specific ones, and has no cloud-native equivalent to build against here. |
| SAP Solution Manager (ChaRM, Focused Build, Focused Insights, EarlyWatch Alert) | SAP itself is moving customers off Solution Manager onto Cloud ALM for cloud-first landscapes (see the dedicated "Transforming for Success with SAP Cloud ALM" learning journey) — building classic Solution Manager coverage would contradict this project's own cloud-native identity. Cloud ALM is the project's monitoring/ITSM-lite story instead. |
| Software Update Manager (SUM) / Database Migration Option (DMO), Brownfield/Bluefield/Greenfield S/4HANA conversion execution | Requires a real on-prem/hybrid S/4HANA system to run against — a Technical Architect/Basis specialization, not something a BTP-only trial landscape can host. |
| On-prem/IaaS HANA administration (system replication, storage-level backup, HA/DR setup, sizing) | HANA Cloud (in scope, `07-data-and-hana-cloud.md`) is SAP-managed; classic on-prem HANA DBA work is a separate specialization. |
| SAP Landscape Management (LaMa) | Orchestrates on-prem/IaaS SAP system lifecycle (clone/copy/refresh) — an infrastructure tool with no natural home in a BTP side-by-side extension project. |
| SAP GRC as a deployed product (Access Control, Process Control) | A dedicated GRC/Security Consultant specialization with its own rule-set configuration. The *concept* of segregation of duties is covered as a design note on the existing Approval/RBAC model; the product suite is not built. |
| Classic SAP Business Workflow (ABAP-based) | Architecturally superseded for cloud-native scenarios by SAP Workflow Management (BPMN-based, which *is* in scope) — classic workflow lives inside the on-prem ABAP stack this project deliberately extends around, not into. |
| Enterprise test-automation tooling (Tricentis Tosca, SAP Business Process Testing) | Licensed third-party tooling aimed at large-scale SAP GUI/S/4HANA UI regression suites — not something a portfolio project can meaningfully stand up. Real Jest test suites already demonstrate testing discipline. |
| SAP Analytics Cloud, SAP Datasphere, SAP Signavio (process mining) | Distinct analytics/BI/process-mining product lines with their own specialist roles — tangential to a BTP extension-development/DevOps identity; including them would be scope creep into a different job family. |
| SAP GUI / transaction-code work generally | The project's whole premise is BTP side-by-side extensibility specifically to *avoid* touching the ABAP-GUI core — reintroducing transaction-code work would contradict the Clean Core principle the charter is built around. |

## Domain coverage map

### `docs/concepts/` — theory, written after building the thing it explains, not before
| File | Covers |
|---|---|
| `01-sap-btp-fundamentals.md` | BTP architecture; CF vs Kyma vs ABAP Environment; global account → directory → subaccount → entitlements model |
| `02-extensibility-and-clean-core.md` | Clean Core principle; side-by-side vs in-app extensibility; when CAP vs when RAP |
| `03-cap-programming-model.md` | CDS, `service.cds`, MTA, multitenancy basics |
| `04-abap-cloud-and-rap.md` | RAP (RESTful ABAP Programming Model); ABAP Cloud; BTP ABAP Environment (Steampunk); gCTS vs abapGit |
| `05-security-xsuaa-destinations.md` | XSUAA; role collections; Destination service; Cloud Connector; principal propagation |
| `06-integration-patterns.md` | Integration Suite (CPI/iFlow); Event Mesh; API Management |
| `07-data-and-hana-cloud.md` | HANA Cloud; HDI containers; Vector Engine for RAG |
| `08-devops-toolchain.md` | Piper; SAP CI/CD service; Cloud Transport Management; gCTS; MTA Build Tool — vs. generic DevOps tooling |
| `09-ai-on-btp.md` | AI Core; AI Launchpad; Generative AI Hub; Joule; Cloud SDK for AI — trial vs free-tier explicitly separated |
| `10-finops-and-licensing.md` | BTP consumption pricing, CPEA, cost governance, a short honest note on Digital Access/indirect-access licensing |
| `00-scope-boundaries.md` | The explicit out-of-scope list above, expanded with reasoning — read this one first, it frames everything else |
| `11-connectivity-cloud-connector.md` | Destination service (proxy types, authentication), Cloud Connector (on-prem tunnel — simulated locally, see `services/legacy-erp-gateway`), Business Application Studio as the standard cloud dev environment |
| `12-multitenancy-and-saas.md` | `@sap/cds-mtxs` (MTX), tenant onboarding/extension model, feature-toggle CDS models |
| `13-cloud-alm-and-operations-services.md` | SAP Cloud ALM (chosen deliberately over classic Solution Manager), Alert Notification Service, Job Scheduling Service, Automation Pilot, Feature Flags service |
| `14-sap-activate-methodology.md` | Discover/Prepare/Explore(Fit-to-Standard)/Realize/Deploy/Run mapped onto this project's own phased roadmap below |

### `services/` — real running code
| Service | What it is |
|---|---|
| `procurement-core` | CAP/Node.js — Suppliers, PurchaseRequisitions, PurchaseOrders, Approvals workflow, OData v4 |
| `supplier-master-abap` | ABAP Cloud/RAP business object on BTP ABAP Environment, OData-exposed, git-versioned via gCTS |
| `spend-anomaly-detector` | Kyma-native event-driven microservice, subscribes to PO-created events via Event Mesh |
| `ai-copilot` | RAG over supplier/contract docs via HANA Vector Engine + LLM, traced via Langfuse (trial/free-tier dual mode, see above) |
| `integration-flow` | Integration Suite iFlow simulating legacy/non-SAP supplier feed ingestion — genuinely cloud-only tooling, stays blocked on the account |
| `legacy-erp-gateway` | A small mock "on-prem" legacy supplier system + a Destination-service-shaped connectivity abstraction in `procurement-core` — simulates the Cloud Connector boundary locally (documented as simulated, not tunneled — there's no real on-prem network segment to tunnel to on a laptop), closing the connectivity gap the research flagged as the project's starkest miss |
| ~~`web-ui`~~ | **Decision (Phase 1)**: built as `procurement-core/srv/service-ui.cds` instead of a separate service — CAP's own convention once a project has real Fiori annotations, and it's what actually generates the List Report + Object Page UI at `/$fiori-preview` with zero hand-written frontend code. A standalone deployable Fiori Elements app (its own `webapp/` + `manifest.json` for html5-repo deployment) is a documented follow-up once deploying to BTP for real — that needs the Fiori Elements Yeoman generator or SAP's Fiori tools, neither of which run headlessly. |

### Platform layer
- `infra/terraform` — `SAP/terraform-provider-btp`: subaccounts (dev/qa/prod), entitlements, CF org/space, Kyma, role collections
- `ci-cd/piper`, `ci-cd/github-actions`, `ci-cd/sap-cicd-service` — three CI/CD paths, documented for what each is best at
- `transport/cloud-transport-management` — CTMS nodes/routes, `.mtaext` per environment, ABAP transport promotion via gCTS

### Operations layer (`docs/operations/`)
- `environments.md` — dev/qa/prod posture across CF + Kyma + ABAP Environment
- `sre-practices.md` — SAP-flavored incident runbooks (failed transport import, XSUAA token failures, HDI binding failures), MTTR tracking, an Automation Pilot-style auto-remediation runbook note
- `observability.md` — **Cloud ALM** (deliberately instead of classic Solution Manager), Application Logging service, Prometheus/Grafana on Kyma, Langfuse for the AI layer
- `fiori-launchpad-administration.md` — a short note distinguishing "building the Fiori Elements app" (done, `procurement-core`) from "exposing it via Launchpad catalogs/spaces/role collections" (an admin concern, documented not built)

### Additional BTP services woven into existing services (not new top-level folders)
| Addition | Where it lives |
|---|---|
| SAP Alert Notification Service + Job Scheduling Service | `spend-anomaly-detector` — a scheduled re-scan job emitting ANS-shaped events on HIGH-severity findings |
| SAP API Management / API Business Hub-style catalog | In front of `procurement-core`'s OData service |
| SAP Feature Flags service (simulated) | Toggles `spend-anomaly-detector`'s rule set or `ai-copilot`'s retrieval mode, with a documented before/after |
| SAP Workflow Management (BPMN) | A documented alternative approval-routing design for `procurement-core`, contrasted with the current in-code threshold routing |
| SAP Document Management Service (simulated) | Replaces `ai-copilot`'s flat local corpus files as the source-of-truth document store |
| Multitenancy / MTX | `procurement-core` gets a documented (and where feasible, built) tenant-onboarding/extension flow via `@sap/cds-mtxs` |

## Phased roadmap (against a ~31-day window, adjust as reality intrudes)

| Phase | Focus | SAP Activate equivalent |
|---|---|---|
| 0 (done) | Charter, repo scaffold | Discover |
| 1 (done) | `procurement-core` CAP service, local dev loop, Fiori Elements UI | Prepare |
| 2 (done) | `ai-copilot` (RAG + local tracer); `spend-anomaly-detector` + real event integration | Explore / Fit-to-Standard — proving the core business scenario works before building the rest of the landscape around it |
| 3 (in progress) | Comprehensiveness gap-check → `legacy-erp-gateway` (Cloud Connector/Destination simulation), scope-boundaries doc, MTX/multitenancy, Feature Flags, Job Scheduling+ANS, API Management layer | Explore (continued) — widening the fit-to-standard model before committing infra |
| 4 | Terraform-provisioned trial landing zone; XSUAA + role collections; HANA Cloud + Vector Engine; CI/CD (Piper + GH Actions) to CF — all account-gated, starts once BTP trial details arrive | Realize |
| 5 | ABAP Cloud/RAP module + gCTS; Kyma deployment; Cloud Transport Management multi-env promotion | Realize (continued) |
| 6 | Integration Suite iFlow; Cloud ALM wiring; SRE/observability docs; test hardening against real deployments | Deploy |
| 7 | Documentation polish, diagrams, publish (GitHub, LinkedIn, Hashnode, SAP Community blog); resume/profile updates | Run |

Phases are sequential but not rigidly day-boxed — resuming work in any session should mean: read this charter, read `docs/next/next.md` for exactly where things were left, then continue. The Activate column isn't decoration — `docs/concepts/14-sap-activate-methodology.md` explains why each phase actually maps the way it does, since that content is now literally embedded in SAP Cloud ALM's own task guidance and answering "how would this run as a real SAP project" is something a pure-code portfolio can't otherwise demonstrate.

## Standards this project holds itself to (matching `ai-ml-llm-ops`)

- Every performance/quality claim backed by a measured number, or explicitly labeled an estimate.
- A "known limitations / honesty notes" section wherever something is aspirational rather than verified — especially the trial-vs-free-tier AI Core split.
- Real tests, real CI runs, real before/after evidence for any fix — not narrated, demonstrated.
- Diagrams (Mermaid) followed by prose explaining *why*, not just *what*.
- Dependency/version pins with inline rationale comments, not bare version ranges.
