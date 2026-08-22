# SAP BTP fundamentals

The orientation doc — what BTP actually is, structurally, before any of the
specific services (CAP, HANA, Kyma, AI Core...) make sense. Written from
research, not yet from hands-on deployment — the deployment-specific docs
(Terraform, XSUAA, Kyma) will get their own concept docs once Phase 2/3
actually stands infrastructure up. This one stays theory-only, deliberately.

## What BTP is

SAP Business Technology Platform is SAP's PaaS: one platform, running on top
of AWS, Azure, GCP, or SAP's own "Alibaba" region, that gives you a database
(HANA Cloud), an application runtime (Cloud Foundry or Kyma/Kubernetes), an
integration layer (Integration Suite), and — increasingly — an AI layer (AI
Core, Generative AI Hub) under one account and billing model. The pitch is
"extend S/4HANA without touching its core" — see `02-extensibility-and-clean-core.md`
(not yet written) for why that separation is the central design principle of
the whole platform, not just a nice-to-have.

## The account hierarchy

```
Global Account
 └── Directory (optional, for grouping)
      └── Subaccount            <- where actual work happens
           ├── Entitlements      (quotas: "this subaccount may use up to N GB HANA Cloud")
           ├── Cloud Foundry environment  (org -> spaces -> apps)
           ├── Kyma environment           (a dedicated managed Kubernetes cluster)
           └── Service instances          (HANA Cloud, XSUAA, Destination, ...)
```

A **subaccount** is the real unit of isolation — its own region, its own
entitlements, its own CF org/Kyma cluster. `sap-btp-platform-engineering`'s
Terraform (Phase 1, not written yet) will provision one subaccount per
environment (dev/qa/prod), matching how `transport/cloud-transport-management`
is meant to promote content between them later.

## The three runtimes, and when each applies

| Runtime | What it actually is | When to reach for it |
|---|---|---|
| **Cloud Foundry** | The original BTP runtime — an org/space model, buildpack-based (push code, CF detects the language, builds+runs it). No Dockerfile needed for a plain CAP app. | Default choice for CAP/Java/Node business services — `procurement-core` targets this first. |
| **Kyma** | SAP's managed Kubernetes distribution — a real K8s cluster, with SAP's own additions (BTP Operator for binding BTP services to pods, APIRule for Istio-based ingress+auth). | When you need containers, sidecars, custom runtimes, or event-driven microservices — `spend-anomaly-detector` (Phase 3) is why this project touches Kyma at all. |
| **ABAP Environment** ("Steampunk") | ABAP-as-a-service — write cloud-clean ABAP (RAP, CDS views) with no on-prem NetWeaver system to maintain. Version-controlled via gCTS/abapGit instead of the classic Transport Organizer. | When the extension is naturally ABAP-shaped — `supplier-master-abap` (Phase 3) exists specifically to cover this, since it's the piece most DevOps-only engineers never touch. |

A single real-world BTP landscape often runs more than one of these
side-by-side against the *same* HANA Cloud instance — which is exactly the
shape `sap-btp-platform-engineering` is aiming to demonstrate, not just pick
one and ignore the rest.

## "Clean Core" — the idea that makes all of this necessary

The old SAP world modified the ERP core directly (custom ABAP bolted into the
S/4HANA system itself) — upgrades became terrifying because nobody could be
sure what custom code would break. Clean Core is the discipline of **never
modifying the core**, only extending it from BTP, side-by-side, talking to the
core over stable, versioned APIs. Every piece of `sap-btp-platform-engineering`
is a Clean Core extension almost by construction: `procurement-core` doesn't
modify any hypothetical S/4HANA procurement tables, it's an independent CAP
service that *would* integrate with one via the Integration Suite piece
(Phase 5) — the S/4HANA core, if this were pointed at a real one, stays
untouched.

## Trial vs. free tier — a distinction that actually blocks things

- **90-day trial**: no card, one subaccount, limited regions, **all data
  permanently deleted at expiry** (no grace period). Covers Cloud Foundry,
  Kyma, HANA Cloud (smaller quota), and ABAP Environment trial.
- **Free tier**: a real (PAYG/CPEA) commercial account, distinguished only by
  a card-verification hold (~$1) and free-tier quotas on eligible services —
  **no time limit**. This is the *only* way to reach **SAP AI Core, AI
  Launchpad, or Generative AI Hub** — they are not offered on the plain trial
  at all, at any quota.

This project starts on the plain trial (see `PROJECT_CHARTER.md`'s account
strategy) — meaning the AI-copilot service (Phase 4) is built in two modes
from day one, not retrofitted later: trial-compatible (external LLM call +
Langfuse tracing, no AI Core) now, with SAP AI Core as a documented, optional
upgrade path once/if the free tier is enabled.

## Why Terraform, not click-ops, for any of this

The trial's 90-day hard deletion is the practical argument, not just DevOps
dogma: if the whole subaccount can vanish on a clock this project doesn't
control, the only sane way to build on it is to make every piece of it
reproducible from code (`infra/terraform`) rather than hand-configured in the
BTP cockpit UI. "Destroy the trial, `terraform apply`, be back to the same
state in minutes" is meant to be a real, demoable property of this project by
the time Phase 1 is done — not just an aspiration stated here.
