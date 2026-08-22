'use strict';

const request = require('supertest');
const { createApp } = require('../src/server');
const jobScheduler = require('../src/job-scheduler');

const app = createApp();

async function submitPO(overrides = {}) {
  return request(app)
    .post('/events/purchase-order-created')
    .send({
      poNumber: `PO-DIGEST-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      totalAmount: 8_000,
      currency: 'USD',
      supplier: { ID: 's1', name: 'Test Supplier', riskRating: 'LOW' },
      items: [{ material: 'Widget', quantity: 1, unitPrice: 8_000 }],
      ...overrides,
    });
}

describe('nightly digest job (SAP Job Scheduling Service target endpoint)', () => {
  beforeEach(() => jobScheduler._resetForTests());

  test('a digest run with zero HIGH-severity reviews in the window publishes no alert', async () => {
    await submitPO(); // LOW-risk, $8,000 - no flags at all
    const res = await request(app).post('/jobs/nightly-digest');
    expect(res.status).toBe(200);
    expect(res.body.alertPublished).toBe(false);
  });

  test('a HIGH-severity review in the window triggers a published alert', async () => {
    await submitPO({
      totalAmount: 65_000,
      supplier: { ID: 's5', name: 'Risky Supplier', riskRating: 'HIGH' },
    });

    const res = await request(app).post('/jobs/nightly-digest');
    expect(res.status).toBe(200);
    expect(res.body.alertPublished).toBe(true);
    expect(res.body.alert.severity).toBe('WARNING');

    const alertsRes = await request(app).get('/alerts');
    expect(alertsRes.body.alerts.length).toBeGreaterThan(0);
    expect(alertsRes.body.alerts[0].subject).toMatch(/HIGH-severity/);
  });

  test('a second consecutive digest run only looks at the new window, not the same review twice', async () => {
    await submitPO({
      totalAmount: 65_000,
      supplier: { ID: 's5', name: 'Risky Supplier', riskRating: 'HIGH' },
    });
    const first = await request(app).post('/jobs/nightly-digest');
    expect(first.body.alertPublished).toBe(true);

    const second = await request(app).post('/jobs/nightly-digest');
    expect(second.body.alertPublished).toBe(false);
    expect(second.body.reviewedCount).toBe(0);
  });
});
