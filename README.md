# SAP BTP Platform Engineering — ProcureIQ

> Status: **local-buildable scope complete, including full documentation coverage. Infrastructure written and validated, deploy pending review.** Five services running and cross-integrated locally, no BTP account needed to build or test any of them. This README is still a placeholder for the eventual full-project overview — see `PROJECT_CHARTER.md` for the plan and each service's own README for what's actually working today.

A hands-on, production-grade platform engineering project on **SAP Business Technology Platform**, built around a real SAP extension scenario — procurement (Purchase Requisition → Purchase Order → Supplier → Contract) — and covering the full SAP DevOps toolchain: CAP, ABAP Cloud/RAP, Cloud Foundry + Kyma, HANA Cloud, XSUAA, Terraform, Project Piper, Cloud Transport Management, gCTS, Integration Suite, and an AI copilot layer (SAP AI Core / Generative AI Hub, with a trial-compatible fallback).

Read `PROJECT_CHARTER.md` first — it has the why, the scope decisions, and the domain coverage map. `docs/concepts/00-scope-boundaries.md` is worth reading right after — it states plainly what this project deliberately does *not* cover, and why.

## Quick links
- [Project Charter](./PROJECT_CHARTER.md) — decisions, scope, roadmap
- [Concepts](./docs/concepts/) — 15 docs, theory written after the thing it explains is built
- [Operations](./docs/operations/) — environments, SRE runbooks, observability, Fiori Launchpad
- [Services](./services/) — running code
- [Infra](./infra/terraform/) — Terraform (`modules/` + `environments/`), validated, not yet applied
- [CI/CD](./ci-cd/) — Piper, GitHub Actions, SAP CI/CD service

## Status

**Five services, all real, tested, and cross-integrated — nothing here needs a BTP account:**

- **`services/procurement-core`** — Requisition → Approval → Purchase Order workflow, real Fiori Elements UI, a `PurchaseOrderCreated` event publisher, and a `syncLegacySuppliers` connectivity action. **17/17 tests.**
- **`services/ai-copilot`** — RAG copilot over procurement documents (Ollama, local tracer), documents itself finding and fixing a real model-capacity issue. **13/13 tests.**
- **`services/spend-anomaly-detector`** — event-driven PO review with real Feature Flags, Alert Notification, and Job Scheduling simulations. **19/19 tests.**
- **`services/legacy-erp-gateway`** — mock on-prem legacy system, the other half of the Cloud Connector/Destination simulation. **2/2 tests.**
- **`services/api-gateway`** — API Management simulation (API keys, rate limiting, API Business Hub-style catalog) in front of `procurement-core`. **16/16 tests.** Live end-to-end testing of this service surfaced and fixed two real bugs — including one that crashed `procurement-core`'s entire server process on a downstream outage, now fixed and verified.

**67/67 tests passing. 51 staged commits.** All 15 concept docs (`00`-`14`) and the full operations layer (`environments.md`, `sre-practices.md`, `observability.md`, `fiori-launchpad-administration.md`) are written — including an explicit, reasoned list of what's deliberately *out* of scope (classic Basis administration, Solution Manager, SUM/DMO, GRC-as-a-product) alongside everything that's in.

**`infra/terraform`** is restructured into real `modules/`+`environments/` conventions (not a flat file dump), every resource verified against the real downloaded provider schema, `terraform validate` passes. Applying happens through GitHub Actions (`terraform-plan.yml` on every PR, `terraform-apply.yml` manual-trigger-only, gated) rather than from a local machine — not yet run, pending an HCP Terraform account for remote state and a final review.

Everything still genuinely blocked on a live, usable BTP account (ABAP Cloud/RAP, Integration Suite, Cloud Transport Management, real Kyma/HANA Cloud/XSUAA, real Langfuse, SAP AI Core) is scoped in `PROJECT_CHARTER.md` — see `docs/next/next.md` for the exact next steps once that account is ready to use.

This section tracks real progress with real numbers as phases complete — no aspirational claims here, ever (see the Charter's "standards" section).
