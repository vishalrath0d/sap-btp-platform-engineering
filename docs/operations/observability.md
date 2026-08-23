# Observability

## What's actually observable today

- **Real Prometheus + Grafana, wired into every service, verified live** —
  each of the five services exposes a genuine Prometheus-format
  `/metrics` endpoint (`prom-client`; `procurement-core`'s is mounted via
  a `cds.on('bootstrap', ...)` custom `server.js`, the other four via
  plain Express middleware — see each service's `src/metrics.js` or
  `srv/lib/metrics.js`). `docker compose up` brings up `prometheus`
  (scraping all five every 15s, `observability/prometheus.yml`) and
  `grafana` (pre-provisioned datasource + a real "ProcureIQ Overview"
  dashboard, `observability/grafana/provisioning/`) with zero manual
  clicking — open `http://localhost:3000` and the dashboard is already
  there. Every metric name and panel was verified against real emitted
  data, not just declared: `procurement_requisitions_approved_total` and
  `procurement_purchase_orders_created_total` confirmed incrementing
  end-to-end through a real `approve` call, `anomaly_reviews_total{severity}`
  confirmed incrementing through a real PO-created event, both queried
  back out of Prometheus's own API, not assumed from the code alone. Beyond
  generic request-rate/latency, the domain-specific panels are the ones
  that actually matter for this system: the requisition lifecycle
  (submitted/approved/rejected — watch for a stuck approval queue), PO
  anomaly reviews by severity, the gateway's rate-limit rejections and
  active API key count, and `ai-copilot`'s Ollama-reachability gauge.
- **`ai-copilot`'s trace/span/generation tracer** (`src/tracer.js`) — real,
  tested, in-memory + JSONL. Every RAG answer's retrieval scores and
  generation prompt are inspectable via `GET /copilot/traces/:id`.
- **`spend-anomaly-detector`'s review + alert log** — every PO review and
  every published alert is queryable (`GET /anomalies`, `GET /alerts`),
  with a full audit trail (which rules fired, why).
- **Structured `console.warn` on every cross-service failure** — e.g.
  `procurement-core`'s event-publish failure logging (see
  `sre-practices.md`'s runbook #1) — not silent, not swallowed.

The trace/log items above are this project's own lightweight local
instrumentation, honestly labeled as such (`ai-copilot`'s tracer is
explicitly a Langfuse-shaped *shim*, not real Langfuse) — but the
Prometheus/Grafana layer is real, standard, off-the-shelf monitoring
tooling, run locally the same way it would be run against any
containerized workload; what's different in a real deployed landscape is
*where* it runs and *what* it scrapes alongside (see below), not whether
the metrics themselves are genuine.

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
OneAgent auto-instrumentation, Davis AI root-cause analysis. Prometheus/
Grafana is real and running in this project (see above) specifically
because it matches the "Developing Applications in SAP BTP Kyma Runtime"
learning journey's own observability unit, which is Prometheus/Grafana-
based for Kubernetes-native workloads — `spend-anomaly-detector`'s
`/metrics` is exactly the shape a real Kyma-side Prometheus would scrape.
The two aren't actually competing choices so much as different layers:
Dynatrace at the platform/APM layer a real SAP shop runs across its whole
landscape (not deployed here — genuinely licensed, enterprise tooling, out
of reach for a portfolio project), Prometheus/Grafana at the Kubernetes-
native metrics layer this project's own services emit directly.

## Langfuse for the AI layer

`ai-copilot`'s local tracer is the trial-mode stand-in — see that
service's README for exactly why real self-hosted Langfuse was deferred
(this machine's Docker Desktop only has 3.8GB RAM allocated, checked
before deciding, not guessed) and what the upgrade path looks like.

## Known limitations (honesty notes)

Every "SAP-native" item in this doc (Cloud ALM, Application Logging
service, Dynatrace) is genuinely undeployed — those need a real BTP
subscription/license this project's trial account doesn't provide. What
*is* real and verified: Prometheus + Grafana, running locally against
every service's genuine `/metrics` endpoint, plus `ai-copilot`'s tracer
and `spend-anomaly-detector`'s review/alert log. `ai-copilot`'s own
`copilot_ollama_reachable` gauge was code-reviewed and wired the same way
as the other four services' metrics, but not independently re-verified
live against a running Ollama instance in this pass (it shares the same
`ai` Compose profile, and pulling its models is a multi-GB, several-minute
step) — the pattern itself (an Express middleware + a `/metrics` route) is
identical to the four services that were verified live, so this is a low-
risk gap, but it's called out rather than silently assumed.
