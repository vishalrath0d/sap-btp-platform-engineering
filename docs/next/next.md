# Continuity notes — read this at the start of every session

Last updated: 2026-08-22 (scaffold session)

## Where things stand
- Repo scaffolded: `docs/{concepts,operations,references,next,diagrams}`, `services/{procurement-core,supplier-master-abap,spend-anomaly-detector,ai-copilot,integration-flow,web-ui}`, `infra/terraform`, `ci-cd/{piper,github-actions,sap-cicd-service}`, `transport/cloud-transport-management`, `scripts/`.
- `PROJECT_CHARTER.md` written — has full scope, domain rationale, account strategy, phased roadmap. Read it first.
- Git repo initialized locally, not yet committed, no GitHub remote yet.
- No BTP trial account exists yet — Vishal is creating it (his action item, not ours).

## Immediate next steps (Phase 1)
1. Once the BTP trial account exists: get Vishal's subaccount details (region, subdomain) — needed before Terraform can target anything real.
2. Write `infra/terraform/` — provider config for `SAP/terraform-provider-btp`, targeting the trial subaccount (entitlements for CF, Kyma, HANA Cloud trial, ABAP Environment trial).
3. Scaffold `services/procurement-core` — CAP/Node.js app, CDS data model (Supplier, PurchaseRequisition, PurchaseOrder, Approval), local `cds watch` dev loop working against SQLite before touching HANA.
4. Get local dev loop fully working and tested before deploying anything to BTP — mirrors how `ai-ml-llm-ops` proved things locally first.

## Open decisions not yet made
- Exact Fiori approach for `web-ui` (Fiori Elements vs. freestyle UI5) — defer until `procurement-core`'s OData service exists to build against.
- Whether the free-tier (PAYG) upgrade for AI Core happens mid-project or is left as a documented "how to extend this" section for later — Vishal said "trial first, free-tier scope for later," revisit once Phase 4 (ai-copilot) is reached.

## Things NOT to do (per explicit user correction)
- Do not reuse or reference `career/03-sap/leverx/projects/demo-phase-3` / `demo-phase-4` as a foundation — it's a toy, explicitly excluded.
- Do not frame this project around any specific interview/interviewer — Vishal already has the EY-GDS offer; this is a general domain-mastery showcase, not interview prep.
