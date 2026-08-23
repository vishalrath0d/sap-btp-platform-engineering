'use strict';

const fs = require('fs');
const path = require('path');
const config = require('./config');
const metrics = require('./metrics');

/**
 * Simulates publishing to SAP Alert Notification Service (ANS). The real
 * ANS ingestion API accepts an event with roughly this shape — eventType,
 * resource, severity, subject/body, tags — this simulation matches that
 * shape closely enough to swap in a real ANS client later, but the exact
 * field names should be re-verified against the live ANS API docs before
 * a real integration, rather than trusted blindly from this simulation.
 *
 * Kept as a separate module from job-scheduler.js on purpose: ANS
 * (publishing alerts) and Job Scheduling (triggering periodic work) are
 * two distinct BTP services in production, wired together here but not
 * the same concern.
 */

const alertsFile = path.join(__dirname, '..', 'data', 'alerts.jsonl');
const alerts = [];

function publishAlert({ severity, subject, body, tags = {} }) {
  const alert = {
    eventType: 'com.procureiq.spend-anomaly-detector.alert',
    resource: { resourceName: 'spend-anomaly-detector', resourceType: 'BTP-App' },
    severity, // INFO | NOTICE | WARNING | ERROR | FATAL
    subject,
    body,
    tags,
    publishedAt: Date.now(),
  };
  alerts.push(alert);
  fs.mkdirSync(path.dirname(alertsFile), { recursive: true });
  fs.appendFileSync(alertsFile, JSON.stringify(alert) + '\n');
  metrics.alertsPublishedTotal.inc();
  return alert;
}

function list(limit = 50) {
  return alerts.slice(-limit).reverse();
}

module.exports = { publishAlert, list };
