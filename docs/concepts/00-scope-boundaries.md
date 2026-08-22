# Scope boundaries — read this first

Every other doc in `docs/concepts/` explains something this project builds.
This one explains what it deliberately does **not** build, and why —
written after a systematic check (session 3) against SAP's own official
[Learning Journeys](https://learning.sap.com), a fresh sweep of real SAP job
postings, and a direct comparison against `ai-ml-llm-ops` (the project's
sibling in the AI/ML/LLM Ops domain) to make sure "comprehensive" here means
the same thing it meant there.

## Why this doc exists

A portfolio project that quietly avoids hard topics looks thin. A portfolio
project that *lists every SAP product it doesn't cover, with a reason* reads
the opposite way — it shows the boundary was a judgment call, not an
oversight. That's the same discipline `ai-ml-llm-ops` applies with its
"known limitations / honesty notes" sections; here it's scoped at the level
of entire specializations instead of individual features.

## What this project *is*

A **BTP-native, cloud-first extension-development and DevOps** project —
CAP, ABAP Cloud/RAP, Cloud Foundry + Kyma, XSUAA, connectivity, CI/CD, AI on
BTP. This is the intersection SAP's own "SAP BTP Developer" and "SAP DevOps
Engineer" job postings actually describe, and the one Vishal is targeting.

## What it deliberately is not

| Not covered | Why | Who it *is* for |
|---|---|---|
| **Classic on-prem Basis administration** — STMS, SPAM/SAINT, SU01/PFCG, SM37/SM21/ST22/DB02, kernel and support-package upgrades | Doesn't appear in BTP-developer or DevOps-engineer job postings — only in Basis-specific ones. No cloud-native equivalent exists to build against; this whole project's premise (BTP side-by-side extension) is structurally about *not* touching the ABAP-GUI core. | SAP Basis Administrator |
| **SAP Solution Manager** — ChaRM, Focused Build, Focused Insights, EarlyWatch Alert | SAP itself is actively moving customers off Solution Manager onto **SAP Cloud ALM** for cloud-first landscapes (there's a dedicated "Transforming for Success with SAP Cloud ALM" learning journey for exactly this migration). Building classic Solution Manager coverage here would contradict the project's own cloud-native identity — Cloud ALM is used instead, see `13-cloud-alm-and-operations-services.md`. | Basis/ALM Consultant on legacy landscapes |
| **SUM/DMO and S/4HANA conversion execution** (Brownfield/Bluefield/Greenfield) | Requires a real on-prem or hybrid S/4HANA system to run a conversion against — not something a BTP-only trial landscape can host. | Technical Architect leading a system conversion |
| **On-prem/IaaS HANA administration** — system replication, storage-level backup, HA/DR, sizing | HANA Cloud (which *is* in scope, `07-data-and-hana-cloud.md`) is SAP-managed. Classic on-prem HANA DBA work is its own specialization. | HANA Database Administrator |
| **SAP Landscape Management (LaMa)** | Orchestrates on-prem/IaaS SAP system lifecycle (clone/copy/refresh) — an infrastructure-automation tool with no natural home in a BTP side-by-side extension project. | Infrastructure/Basis teams managing large on-prem landscapes |
| **SAP GRC as a deployed product** — Access Control, Process Control | A dedicated specialization with its own rule-set configuration and licensing. The underlying *concept* — segregation of duties — is covered as a design note on this project's own Approval/RBAC model (a requester can never also be the approver of their own requisition, enforced structurally, not just as policy); the product suite itself is not built. | GRC/Security Consultant |
| **Classic SAP Business Workflow** (ABAP-based) | Architecturally superseded for cloud-native scenarios by **SAP Workflow Management** (BPMN-based, which *is* in scope) — classic workflow lives inside the on-prem ABAP stack this project extends around, not into. | ABAP developer on an on-prem workflow |
| **Enterprise test-automation tooling** — Tricentis Tosca, SAP Business Process Testing | Licensed third-party tooling for large-scale SAP GUI/S/4HANA UI regression suites — not something a portfolio project can meaningfully stand up. This project's real Jest suites (33/33 passing across three services as of session 2) already demonstrate testing discipline at the level that's actually reproducible here. | QA/Test Automation Engineer |
| **SAP Analytics Cloud, SAP Datasphere, SAP Signavio** | Distinct analytics/BI and process-mining product lines with their own specialist roles. Including them would be scope creep into a different job family entirely, not comprehensiveness. | SAC Consultant / Data Engineer / Process Analyst |
| **SAP GUI / transaction-code work generally** | The project's whole premise is BTP side-by-side extensibility specifically to *avoid* touching the ABAP-GUI core (the **Clean Core** principle — see `02-extensibility-and-clean-core.md`). Reintroducing transaction-code work would contradict that. | On-prem ABAP/functional consultant |

## What's in scope that wasn't originally planned

Session 3's gap-check against SAP's own Learning Journeys surfaced real,
BTP-native gaps this project *should* have and originally didn't — these are
now in the coverage map in `PROJECT_CHARTER.md`: Destination service + Cloud
Connector connectivity (the single starkest gap found — see
`11-connectivity-cloud-connector.md`), SAP Business Application Studio,
multitenancy/MTX (`12-multitenancy-and-saas.md`), SAP Cloud ALM, Alert
Notification + Job Scheduling services, API Management, Feature Flags
service, SAP Automation Pilot, SAP Workflow Management, and SAP Document
Management Service. None of these are padding — each ties to either a named
unit in an official SAP Learning Journey or a specific, recurring line in
real job postings (both cited in `PROJECT_CHARTER.md`'s scope-expansion
section).
