'use strict';

const express = require('express');
const fs = require('fs');
const path = require('path');

const SUPPLIERS = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data', 'suppliers.json'), 'utf8'));
const PORT = process.env.PORT || 4007;

/**
 * Deliberately shaped like a real legacy on-prem system, not a clean BTP
 * service: cryptic field names (CTRY_CD, RISK_CD), single-letter status
 * codes, no OData/CDS conventions. procurement-core's mapping layer
 * (srv/lib/legacy-supplier-mapper.js) exists specifically to translate
 * this into the clean domain model — that mapping work is itself a real,
 * common integration-developer task, not incidental plumbing.
 */
function createApp() {
  const app = express();

  app.get('/health', (req, res) => res.json({ status: 'ok', recordCount: SUPPLIERS.length }));

  app.get('/legacy/suppliers', (req, res) => {
    res.json(SUPPLIERS);
  });

  return app;
}

if (require.main === module) {
  createApp().listen(PORT, () => {
    console.log(`[legacy-erp-gateway] listening on http://localhost:${PORT} (simulating an on-prem legacy system)`);
  });
}

module.exports = { createApp };
