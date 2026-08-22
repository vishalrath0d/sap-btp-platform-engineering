# SAP BTP Platform Engineering — ProcureIQ

> Status: **local-buildable scope complete, BTP-dependent scope next**. Three services running and cross-integrated, fully locally, no BTP account needed. This README is still a placeholder for the eventual full-project overview — see `PROJECT_CHARTER.md` for the plan and each service's own README for what's actually working today.

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

**Three services, all real, tested, and cross-integrated — nothing here needs a BTP account:**

- **`services/procurement-core`** (CAP/Node.js) — Requisition → threshold-routed Approval → auto-generated Purchase Order workflow, RBAC via mocked auth, **9/9 tests**. Also serves a real **SAP Fiori Elements UI** generated from CDS annotations (zero hand-written frontend code) and **publishes a `PurchaseOrderCreated` event** on every approval.
- **`services/ai-copilot`** — RAG copilot over procurement policy/contract documents via Ollama, with a local Langfuse-shaped tracer for full retrieval/generation provenance, **11/11 tests** (6 unit, 5 live against real Ollama). Documents a real model-size finding (0.5B model failed cross-document synthesis that a verifiably-present-in-context answer required; 1.5B fixed it).
- **`services/spend-anomaly-detector`** — event-driven PO review (4 deterministic, explainable rules), **13/13 tests**. Verified live end-to-end: a normal PO produces a clean review, a large PO against a HIGH-risk supplier correctly triggers 3 flags.

**33/33 tests passing** across the three services. **16 staged commits**, each with a real rationale, several documenting actual bugs found and fixed along the way (a broken macOS toolchain, CAP naming-convention gotchas, a test-arithmetic mistake, a UI criticality-coloring bug) rather than smoothing them over.

Everything else in the domain coverage map (ABAP Cloud/RAP, Terraform, real Kyma/HANA Cloud/XSUAA, CI/CD against a real target, Cloud Transport Management, Integration Suite, real Langfuse, SAP AI Core) is scoped in `PROJECT_CHARTER.md` and genuinely blocked on a live BTP account — see `docs/next/next.md` for exactly what's next once that exists.

This section tracks real progress with real numbers as phases complete — no aspirational claims here, ever (see the Charter's "standards" section).
