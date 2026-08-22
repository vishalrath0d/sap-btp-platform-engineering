# SAP BTP Platform Engineering — ProcureIQ

> Status: **Phase 1 in progress**. `procurement-core` is real, running, and tested locally. This README is still a placeholder for the eventual full-project overview — see `PROJECT_CHARTER.md` for the plan and `services/procurement-core/README.md` for what's actually working today.

A hands-on, production-grade platform engineering project on **SAP Business Technology Platform**, built around a real SAP extension scenario — procurement (Purchase Requisition → Purchase Order → Supplier → Contract) — and covering the full SAP DevOps toolchain: CAP, ABAP Cloud/RAP, Cloud Foundry + Kyma, HANA Cloud, XSUAA, Terraform, Project Piper, Cloud Transport Management, gCTS, Integration Suite, and an AI copilot layer (SAP AI Core / Generative AI Hub, with a trial-compatible fallback).

Read `PROJECT_CHARTER.md` first — it has the why, the scope decisions, and the domain coverage map.

## Quick links
- [Project Charter](./PROJECT_CHARTER.md) — decisions, scope, roadmap
- [Concepts](./docs/concepts/) — theory docs, written after the thing they explain is built
- [Services](./services/) — running code
- [Infra](./infra/) — Terraform
- [CI/CD](./ci-cd/) — Piper, GitHub Actions, SAP CI/CD service
- [Transport](./transport/) — Cloud Transport Management config

## Status

- **`services/procurement-core`** — CAP (Node.js) service, runs fully locally (SQLite, no BTP account needed). Real workflow: `submit` → threshold-routed `Approval` → `approve` auto-generates a `PurchaseOrder` with items copied from the requisition, or `rejectRequisition`. Role-based access via CAP's mocked auth (Requester/Approver). **9/9 tests passing** (`npm test` in that folder) — happy paths, RBAC enforcement, and business-rule guards all verified against a real running server, not just unit-mocked. Two real bugs hit and fixed during the build are documented in that service's README rather than smoothed over.
- Everything else in the domain coverage map (ABAP Cloud/RAP, Kyma, HANA Cloud, Terraform, CI/CD, AI copilot, Integration Suite, Fiori UI) is scoped in `PROJECT_CHARTER.md` but not started yet.

This section tracks real progress with real numbers as phases complete — no aspirational claims here, ever (see the Charter's "standards" section).
