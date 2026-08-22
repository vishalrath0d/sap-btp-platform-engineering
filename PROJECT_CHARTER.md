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
| `10-finops-and-licensing.md` | BTP consumption pricing, CPEA, cost governance |

### `services/` — real running code
| Service | What it is |
|---|---|
| `procurement-core` | CAP/Node.js — Suppliers, PurchaseRequisitions, PurchaseOrders, Approvals workflow, OData v4 |
| `supplier-master-abap` | ABAP Cloud/RAP business object on BTP ABAP Environment, OData-exposed, git-versioned via gCTS |
| `spend-anomaly-detector` | Kyma-native event-driven microservice, subscribes to PO-created events via Event Mesh |
| `ai-copilot` | RAG over supplier/contract docs via HANA Vector Engine + LLM, traced via Langfuse (trial/free-tier dual mode, see above) |
| `integration-flow` | Integration Suite iFlow simulating legacy/non-SAP supplier feed ingestion |
| `web-ui` | Fiori Elements or UI5 front end over the OData services |

### Platform layer
- `infra/terraform` — `SAP/terraform-provider-btp`: subaccounts (dev/qa/prod), entitlements, CF org/space, Kyma, role collections
- `ci-cd/piper`, `ci-cd/github-actions`, `ci-cd/sap-cicd-service` — three CI/CD paths, documented for what each is best at
- `transport/cloud-transport-management` — CTMS nodes/routes, `.mtaext` per environment, ABAP transport promotion via gCTS

### Operations layer (`docs/operations/`)
- `environments.md` — dev/qa/prod posture across CF + Kyma + ABAP Environment
- `sre-practices.md` — SAP-flavored incident runbooks (failed transport import, XSUAA token failures, HDI binding failures), MTTR tracking
- `observability.md` — Cloud ALM, Application Logging service, Prometheus/Grafana on Kyma, Langfuse for the AI layer

## Phased roadmap (against a ~31-day window, adjust as reality intrudes)

| Phase | Focus |
|---|---|
| 0 (done) | Charter, repo scaffold |
| 1 | Terraform-provisioned trial landing zone; `procurement-core` CAP service; local dev loop |
| 2 | XSUAA + role collections; HANA Cloud + Vector Engine; CI/CD (Piper + GH Actions) to CF |
| 3 | ABAP Cloud/RAP module + gCTS; `spend-anomaly-detector` on Kyma |
| 4 | `ai-copilot` (RAG + Langfuse); Cloud Transport Management multi-env promotion |
| 5 | Integration Suite iFlow; Fiori UI; observability/SRE docs; test hardening |
| 6 | Documentation polish, diagrams, publish (GitHub, LinkedIn, Hashnode, SAP Community blog); resume/profile updates |

Phases are sequential but not rigidly day-boxed — resuming work in any session should mean: read this charter, read `docs/next/next.md` for exactly where things were left, then continue.

## Standards this project holds itself to (matching `ai-ml-llm-ops`)

- Every performance/quality claim backed by a measured number, or explicitly labeled an estimate.
- A "known limitations / honesty notes" section wherever something is aspirational rather than verified — especially the trial-vs-free-tier AI Core split.
- Real tests, real CI runs, real before/after evidence for any fix — not narrated, demonstrated.
- Diagrams (Mermaid) followed by prose explaining *why*, not just *what*.
- Dependency/version pins with inline rationale comments, not bare version ranges.
