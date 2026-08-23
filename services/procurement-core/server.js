'use strict';

// Custom CAP server bootstrap - the real, documented CAP mechanism for
// mounting a custom/best-practice Express middleware before CDS serves
// its own OData services (verified against capire's "Bootstrapping
// Servers" docs, not guessed): a project-root server.js exporting
// `cds.server` after registering `cds.on('bootstrap', app => ...)`
// handlers. package.json's "main" points here so both `cds-serve` (this
// service's real start script) and `cds watch` pick it up.
//
// Metrics only, on purpose - this file doesn't touch CDS's own request
// handling (auth, OData dispatch, DB access all still happen exactly as
// they did with no custom server.js at all); it only adds one middleware
// and one route to the same Express app CDS would have created anyway.
const cds = require('@sap/cds');
const metrics = require('./srv/lib/metrics');

cds.on('bootstrap', (app) => {
  app.use(metrics.httpMiddleware);
  app.get('/metrics', metrics.handler);
});

module.exports = cds.server;
