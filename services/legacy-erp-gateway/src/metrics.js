'use strict';

const client = require('prom-client');

// Deliberately minimal - this service is a static mock legacy system (see
// its own README), so generic request count/latency is the whole real
// signal worth exposing; inventing domain-specific gauges here would be
// padding, not honest instrumentation.
const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'legacy_' });

const httpRequestsTotal = new client.Counter({
  name: 'legacy_http_requests_total',
  help: 'Total HTTP requests handled by legacy-erp-gateway',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'legacy_http_request_duration_seconds',
  help: 'legacy-erp-gateway request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

function httpMiddleware(req, res, next) {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    const route = req.route?.path || req.path;
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

module.exports = { httpMiddleware, handler };
