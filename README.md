# SAP BTP Platform Engineering — ProcureIQ

> Status: **scaffolding phase**. This README is a placeholder — it will be rewritten once Phase 1 has real, running code to describe. See `PROJECT_CHARTER.md` for the full plan.

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

Nothing is built yet beyond the repo skeleton and the charter. This section will track real progress with real numbers as phases complete — no aspirational claims here, ever (see the Charter's "standards" section).
