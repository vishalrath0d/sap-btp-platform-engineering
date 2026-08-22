'use strict';

module.exports = {
  port: process.env.PORT || 4008,
  procurementCoreUrl: process.env.PROCUREMENT_CORE_URL || 'http://localhost:4004/procurement',
  rateLimitWindowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000),
  rateLimitMax: Number(process.env.RATE_LIMIT_MAX || 10),
};
