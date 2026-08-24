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

## Now deployed: the same `/metrics` endpoints, live on BTP

All 5 services are deployed and running on Cloud Foundry (see the root
README's "Live on BTP" section) — the exact same `prom-client`
`/metrics` endpoints documented above are reachable over the public
internet right now, verified directly, not assumed:

```bash
curl -s https://api-gateway.cfapps.us10-001.hana.ondemand.com/metrics | head -20
curl -s https://ai-copilot.cfapps.us10-001.hana.ondemand.com/copilot/health
# -> {"status":"degraded","ollamaReachable":false,"embeddingModel":"all-minilm",
#     "chatModel":"qwen2.5:1.5b","corpusChunks":0}
```

**What's genuinely different from local, and what isn't:** the metrics
themselves are the identical code path (same `metrics.js`, same
`prom-client` counters/histograms) — only *where they're scraped from*
changes. Locally, `docker-compose.yml`'s `prometheus` container scrapes
all five every 15s and Grafana's pre-provisioned dashboard reads from
it. **On BTP, nothing is scraping these endpoints yet** — no Prometheus
instance is pointed at the deployed apps, so there's no live Grafana
dashboard for the deployed system today. This is a real, honest gap,
not hidden: the endpoints exist and are correct (curl them directly
above), the scraper/dashboard layer on top of them simply isn't stood
up against BTP yet. Closing it for real would mean either a Kyma-side
Prometheus (once the pending Kyma approval lands — see
`infra/terraform/README.md`) scraping across both CF and Kyma, or SAP's
own **Continuous Delivery / Cloud ALM Monitoring** wired to each app's
route — either is a genuine next step, not attempted this session.

**`cf logs` works right now, no separate setup** — this is real,
already-available BTP tooling, distinct from the Application Logging
service below:

```bash
cf logs api-gateway --recent   # or any of the other 4 app names
```

The cockpit's own **Applications → app → Logs** tab (see
`docs/operations/btp-cockpit-navigation.md`) is the same thing without
the CLI — both read the same real, live stdout/stderr from the running
container, no shipping/aggregation step required for a single app on a
single space.

## SAP Application Logging service

BTP's managed log aggregation for Cloud Foundry apps, layered on top of
what `cf logs`/the cockpit's Logs tab already gives you for free — the
natural destination once retention/search across restarts or multiple
apps at once matters (`cf logs --recent` only shows a rolling recent
buffer per app, not a searchable history). Not yet subscribed — for a
single-space trial with `cf logs` already covering real, live debugging
needs (used throughout this session to diagnose every deploy failure),
standing up a separate log-aggregation subscription hasn't been
necessary yet, not because it's unavailable.

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

Cloud ALM and Dynatrace are genuinely undeployed — those need a real BTP
subscription/license this project's trial account doesn't provide.
Application Logging service is available on this trial but not
subscribed (see above — `cf logs` already covers this project's real
debugging needs at its current scale). What *is* real and verified:
Prometheus + Grafana running locally against every service's genuine
`/metrics` endpoint, the identical `/metrics` endpoints now also live
and directly curlable on the real deployed BTP apps (verified this
session, see above — just not yet scraped/dashboarded there), `cf logs`
against the real deployed apps (used throughout this session to
diagnose every real deploy failure — see `infra/terraform/README.md`'s
"What's verified" section for the actual bugs found this way), plus
`ai-copilot`'s tracer and `spend-anomaly-detector`'s review/alert log.
`ai-copilot`'s own `copilot_ollama_reachable` gauge is confirmed `false`
on the real deployed app (`{"status":"degraded","ollamaReachable":
false,...}` — no Ollama on CF, degrades gracefully by design; see that
service's own README and the fix documented in
`services/ai-copilot/src/server.js`'s `main()`).
