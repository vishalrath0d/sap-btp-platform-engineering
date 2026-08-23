'use strict';

const client = require('prom-client');

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'anomaly_' });

const httpRequestsTotal = new client.Counter({
  name: 'anomaly_http_requests_total',
  help: 'Total HTTP requests handled by spend-anomaly-detector',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'anomaly_http_request_duration_seconds',
  help: 'spend-anomaly-detector request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// The actual thing worth dashboarding for this service: how many POs get
// reviewed, split by the severity rules.evaluate() assigned - a real
// production alert would fire on a sudden spike in HIGH-severity reviews,
// not on request count.
const reviewsTotal = new client.Counter({
  name: 'anomaly_reviews_total',
  help: 'Purchase order reviews recorded, by severity',
  labelNames: ['severity'],
  registers: [register],
});

const alertsPublishedTotal = new client.Counter({
  name: 'anomaly_alerts_published_total',
  help: 'Alerts published via the simulated Alert Notification Service outbox',
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

module.exports = { httpMiddleware, handler, reviewsTotal, alertsPublishedTotal };
