# Observability

## What's actually observable today

- **`ai-copilot`'s trace/span/generation tracer** (`src/tracer.js`) — real,
  tested, in-memory + JSONL. Every RAG answer's retrieval scores and
  generation prompt are inspectable via `GET /copilot/traces/:id`.
- **`spend-anomaly-detector`'s review + alert log** — every PO review and
  every published alert is queryable (`GET /anomalies`, `GET /alerts`),
  with a full audit trail (which rules fired, why).
- **Structured `console.warn` on every cross-service failure** — e.g.
  `procurement-core`'s event-publish failure logging (see
  `sre-practices.md`'s runbook #1) — not silent, not swallowed.

None of this is SAP-native tooling yet — it's this project's own
lightweight local instrumentation, honestly labeled as such throughout
(`ai-copilot`'s tracer is explicitly a Langfuse-shaped *shim*, not real
Langfuse).

## Cloud ALM — chosen deliberately, not yet connected

See `docs/concepts/13-cloud-alm-and-operations-services.md` for the full
reasoning (Cloud ALM instead of classic Solution Manager, matching SAP's
own migration direction). Not yet subscribed/connected — documented
intent.

## SAP Application Logging service

BTP's managed log aggregation for Cloud Foundry apps — the natural
destination for the `console.warn`/`console.log` output every service in
this project already produces, once deployed. Not yet wired — local dev
just reads stdout directly, which is sufficient for now and honestly
simpler than standing up log shipping for a project with no real traffic
yet.

## Dynatrace vs. Prometheus/Grafana — a real-world note, not a design choice made here

Worth naming plainly: **Dynatrace**, not Prometheus/Grafana, is what SAP's
own internal platform teams and real client landscapes (per this
project's own interview-prep research — EY's real client environments,
SAP's internal DLM unit) actually run for APM/infrastructure monitoring —
OneAgent auto-instrumentation, Davis AI root-cause analysis. This project
uses Prometheus/Grafana conceptually for the Kyma-side services (matching
the "Developing Applications in SAP BTP Kyma Runtime" learning journey's
own observability unit, which is Prometheus/Grafana-based for Kubernetes-
native workloads specifically) — the two aren't actually competing
choices so much as different layers: Dynatrace at the platform/APM layer
a real SAP shop runs, Prometheus/Grafana at the Kubernetes-native metrics
layer this project's own Kyma-targeted services would emit. Neither is
deployed in this project yet.

## Langfuse for the AI layer

`ai-copilot`'s local tracer is the trial-mode stand-in — see that
service's README for exactly why real self-hosted Langfuse was deferred
(this machine's Docker Desktop only has 3.8GB RAM allocated, checked
before deciding, not guessed) and what the upgrade path looks like.

## Known limitations (honesty notes)

Every "SAP-native" item in this doc (Cloud ALM, Application Logging
service, Dynatrace) is genuinely undeployed — this project's real,
verified observability is currently limited to the custom instrumentation
built into `ai-copilot` and `spend-anomaly-detector` themselves.
