'use strict';

const express = require('express');
const config = require('./config');
const rules = require('./rules');
const store = require('./store');
const featureFlags = require('./feature-flags');
const jobScheduler = require('./job-scheduler');
const alertNotification = require('./alert-notification');

function createApp() {
  const app = express();
  app.use(express.json());

  app.get('/health', (req, res) => {
    res.json({ status: 'ok', reviewedCount: store.list({ limit: 1e9 }).length });
  });

  /**
   * Local stand-in for a Kyma event subscription. In production this
   * service subscribes to a `PurchaseOrderCreated` topic on SAP Event Mesh
   * instead of exposing an HTTP endpoint — the payload shape and the
   * evaluate() logic don't change, only how the payload arrives. See
   * README for why this project uses an HTTP webhook locally instead of
   * standing up a real broker.
   */
  app.post('/events/purchase-order-created', (req, res) => {
    const po = req.body || {};
    if (!po.poNumber || po.totalAmount == null) {
      return res.status(400).json({ error: 'poNumber and totalAmount are required' });
    }

    const { flags, severity } = rules.evaluate(po);
    const review = store.record(po.poNumber, {
      severity,
      flags,
      totalAmount: po.totalAmount,
      currency: po.currency,
      supplierId: po.supplier?.ID,
      sourceRequisitionId: po.sourceRequisitionId,
    });

    res.status(201).json(review);
  });

  app.get('/anomalies', (req, res) => {
    res.json({ reviews: store.list({ flaggedOnly: req.query.flaggedOnly === 'true' }) });
  });

  app.get('/anomalies/:poNumber', (req, res) => {
    const review = store.get(req.params.poNumber);
    if (!review) return res.status(404).json({ error: `no review on record for ${req.params.poNumber}` });
    res.json(review);
  });

  // Simulated SAP Feature Flags service admin surface — toggling behavior
  // at runtime, no redeploy. See src/feature-flags.js.
  app.get('/admin/flags', (req, res) => {
    res.json({ flags: featureFlags.list() });
  });

  app.put('/admin/flags/:name', (req, res) => {
    try {
      const flag = featureFlags.setEnabled(req.params.name, req.body?.enabled);
      res.json(flag);
    } catch (err) {
      res.status(404).json({ error: err.message });
    }
  });

  /**
   * The endpoint a real SAP Job Scheduling Service job definition would
   * call on a cron schedule (e.g. nightly). See src/job-scheduler.js for
   * why there's no in-app scheduler here.
   */
  app.post('/jobs/nightly-digest', (req, res) => {
    res.json(jobScheduler.runNightlyDigest());
  });

  // Simulated SAP Alert Notification Service outbox.
  app.get('/alerts', (req, res) => {
    res.json({ alerts: alertNotification.list(Number(req.query.limit) || 50) });
  });

  return app;
}

if (require.main === module) {
  createApp().listen(config.port, () => {
    console.log(`[spend-anomaly-detector] listening on http://localhost:${config.port}`);
  });
}

module.exports = { createApp };
