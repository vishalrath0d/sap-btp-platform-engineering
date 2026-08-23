'use strict';

const client = require('prom-client');

// One registry per process, real Prometheus-format /metrics - the local
// stand-in for what a real deployed landscape would scrape via Kyma-side
// Prometheus/Application Logging (see docs/operations/observability.md).
// collectDefaultMetrics adds Node's own process/event-loop/GC metrics for
// free - real signal (memory growth, event-loop lag), not just app-level
// counters.
const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'gateway_' });

const httpRequestsTotal = new client.Counter({
  name: 'gateway_http_requests_total',
  help: 'Total HTTP requests handled by api-gateway',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'gateway_http_request_duration_seconds',
  help: 'api-gateway request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// Domain-specific, not generic HTTP noise - the two things actually worth
// alerting on for a gateway: are consumers getting throttled, and how
// many are even registered right now.
const rateLimitExceededTotal = new client.Counter({
  name: 'gateway_rate_limit_exceeded_total',
  help: 'Requests rejected for exceeding the per-key rate limit',
  registers: [register],
});

const activeApiKeys = new client.Gauge({
  name: 'gateway_active_api_keys',
  help: 'Number of currently-active (non-revoked) API keys',
  registers: [register],
});

function httpMiddleware(req, res, next) {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    // req.route is only set once Express matches a route; for the
    // catch-all /api/v1 proxy there's no per-sub-path route object, so
    // fall back to the mount path - still meaningfully distinguishes
    // "the proxy" from "the admin endpoints" without an unbounded label
    // cardinality explosion from every possible upstream path.
    const route = req.route?.path || req.baseUrl || req.path;
    const labels = { method: req.method, route, status: String(res.statusCode) };
    httpRequestsTotal.inc(labels);
    const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
    httpRequestDuration.observe(labels, durationSeconds);
  });
  next();
}

async function handler(req, res) {
  res.set('Content-Type', register.contentType);
  res.send(await register.metrics());
}

module.exports = { httpMiddleware, handler, rateLimitExceededTotal, activeApiKeys };
