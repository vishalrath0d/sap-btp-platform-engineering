'use strict';

const client = require('prom-client');

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'copilot_' });

const httpRequestsTotal = new client.Counter({
  name: 'copilot_http_requests_total',
  help: 'Total HTTP requests handled by ai-copilot',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'copilot_http_request_duration_seconds',
  help: 'ai-copilot request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.05, 0.1, 0.5, 1, 2.5, 5, 10, 20],
  registers: [register],
});

// The MLOps/LLMOps-shaped signal this service can actually offer: is the
// embedding/chat backend even reachable right now (this service's own
// /copilot/health already answers this per-request; this gauge is the
// same fact, in a form a dashboard/alert can graph over time), and how
// often a real question comes in.
const ollamaReachable = new client.Gauge({
  name: 'copilot_ollama_reachable',
  help: '1 if Ollama was reachable on the most recent check, 0 otherwise',
  registers: [register],
});

const questionsTotal = new client.Counter({
  name: 'copilot_questions_total',
  help: 'Questions answered via /copilot/ask, by outcome',
  labelNames: ['status'],
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

module.exports = { httpMiddleware, handler, ollamaReachable, questionsTotal };
