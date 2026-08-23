'use strict';

const client = require('prom-client');

// Mounted onto the underlying Express app via cds.on('bootstrap') in the
// project-root server.js, not a plain Express service the way the other
// four services' metrics.js are - CAP owns the HTTP server here, so this
// module only defines the metrics/registry; server.js does the actual
// mounting. See server.js's comment for why that split is real CAP
// convention, not a workaround.
const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'procurement_' });

const httpRequestsTotal = new client.Counter({
  name: 'procurement_http_requests_total',
  help: 'Total HTTP requests handled by procurement-core',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'procurement_http_request_duration_seconds',
  help: 'procurement-core request latency in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [register],
});

// The actual business events worth graphing for this service - the
// requisition lifecycle itself, not just HTTP noise. A real dashboard
// would put submitted/approved/rejected side by side to watch for a
// stuck approval queue (submitted climbing, approved flat).
const requisitionsSubmittedTotal = new client.Counter({
  name: 'procurement_requisitions_submitted_total',
  help: 'Purchase requisitions moved from DRAFT to SUBMITTED',
  registers: [register],
});

const requisitionsApprovedTotal = new client.Counter({
  name: 'procurement_requisitions_approved_total',
  help: 'Purchase requisitions approved (and converted to a Purchase Order)',
  registers: [register],
});

const requisitionsRejectedTotal = new client.Counter({
  name: 'procurement_requisitions_rejected_total',
  help: 'Purchase requisitions rejected',
  registers: [register],
});

const purchaseOrdersCreatedTotal = new client.Counter({
  name: 'procurement_purchase_orders_created_total',
  help: 'Purchase Orders created from an approved requisition',
  registers: [register],
});

function httpMiddleware(req, res, next) {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    // CAP's own OData routing doesn't populate req.route the way plain
    // Express handlers do - req.path (e.g. /procurement/PurchaseRequisitions)
    // is the meaningful, bounded-cardinality label here instead.
    const labels = { method: req.method, route: req.path, status: String(res.statusCode) };
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

module.exports = {
  httpMiddleware,
  handler,
  requisitionsSubmittedTotal,
  requisitionsApprovedTotal,
  requisitionsRejectedTotal,
  purchaseOrdersCreatedTotal,
};
