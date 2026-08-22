'use strict';

const request = require('supertest');
const { createApp } = require('../src/server');

const app = createApp();

const basePO = {
  poNumber: `PO-TEST-${Date.now()}`,
  totalAmount: 8400,
  currency: 'USD',
  supplier: { ID: 's1', name: 'Acme Components Ltd', riskRating: 'LOW' },
  sourceRequisitionId: 'req-1',
  items: [{ material: 'Widget', quantity: 4, unitPrice: 2100 }],
};

describe('spend-anomaly-detector API', () => {
  test('POST /events/purchase-order-created rejects a payload missing required fields', async () => {
    const res = await request(app).post('/events/purchase-order-created').send({});
    expect(res.status).toBe(400);
  });

  test('POST /events/purchase-order-created evaluates and stores a review', async () => {
    const res = await request(app).post('/events/purchase-order-created').send(basePO);
    expect(res.status).toBe(201);
    expect(res.body.severity).toBe('NONE');
    expect(res.body.poNumber).toBe(basePO.poNumber);
  });

  test('GET /anomalies/:poNumber returns the stored review', async () => {
    const res = await request(app).get(`/anomalies/${basePO.poNumber}`);
    expect(res.status).toBe(200);
    expect(res.body.poNumber).toBe(basePO.poNumber);
  });

  test('GET /anomalies/:poNumber 404s for an unknown PO', async () => {
    const res = await request(app).get('/anomalies/PO-DOES-NOT-EXIST');
    expect(res.status).toBe(404);
  });

  test('GET /anomalies?flaggedOnly=true excludes clean reviews', async () => {
    const flagged = { ...basePO, poNumber: `PO-FLAGGED-${Date.now()}`, totalAmount: 99_000 };
    await request(app).post('/events/purchase-order-created').send(flagged);

    const res = await request(app).get('/anomalies?flaggedOnly=true');
    const numbers = res.body.reviews.map((r) => r.poNumber);
    expect(numbers).toContain(flagged.poNumber);
    expect(numbers).not.toContain(basePO.poNumber); // the clean one from the earlier test
  });
});
