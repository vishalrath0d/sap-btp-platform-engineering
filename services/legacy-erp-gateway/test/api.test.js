'use strict';

const request = require('supertest');
const { createApp } = require('../src/server');

const app = createApp();

describe('legacy-erp-gateway', () => {
  test('GET /health reports a record count', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.recordCount).toBeGreaterThan(0);
  });

  test('GET /legacy/suppliers returns records in the legacy shape, not the clean domain shape', async () => {
    const res = await request(app).get('/legacy/suppliers');
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    const record = res.body[0];
    // Deliberately legacy field names — this test would fail if someone
    // "cleaned up" the mock to look like the real Suppliers entity, which
    // would defeat the point of having a mapping layer to test at all.
    expect(record).toHaveProperty('SUPPLIER_ID');
    expect(record).toHaveProperty('RISK_CD');
    expect(record).toHaveProperty('REC_STATUS');
    expect(record).not.toHaveProperty('riskRating');
  });
});
