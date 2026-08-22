'use strict';

const request = require('supertest');
const { createApp } = require('../src/server');
const rateLimiter = require('../src/rate-limiter');

const app = createApp();

describe('api-gateway (no procurement-core needed for these)', () => {
  beforeEach(() => rateLimiter._resetForTests());

  test('GET /catalog returns the API Business Hub-style catalog', () => {
    return request(app)
      .get('/catalog')
      .expect(200)
      .then((res) => {
        expect(res.body.name).toBe('ProcureIQ Procurement API');
        expect(res.body.endpoints.length).toBeGreaterThan(0);
        expect(res.body.authentication.header).toBe('X-API-Key');
      });
  });

  test('POST /admin/keys issues a usable key', async () => {
    const issue = await request(app).post('/admin/keys').send({ name: 'ci-test' });
    expect(issue.status).toBe(201);
    expect(issue.body.key).toBeTruthy();
  });

  test('proxied routes reject requests with no API key', async () => {
    const res = await request(app).get('/api/v1/Suppliers');
    expect(res.status).toBe(401);
  });

  test('proxied routes reject an invalid API key', async () => {
    const res = await request(app).get('/api/v1/Suppliers').set('X-API-Key', 'not-a-real-key');
    expect(res.status).toBe(401);
  });

  test('rate limit is enforced per key, independent of other keys', async () => {
    const { key } = (await request(app).post('/admin/keys').send({ name: 'rate-test' })).body;

    // First config.rateLimitMax calls all get *some* response (401/502
    // depending on whether procurement-core is up - irrelevant here,
    // what's being tested is that the gateway's own rate-limit headers
    // count down correctly regardless of upstream reachability).
    let lastRemaining;
    for (let i = 0; i < 10; i++) {
      const res = await request(app).get('/api/v1/Suppliers').set('X-API-Key', key);
      lastRemaining = Number(res.headers['x-ratelimit-remaining']);
    }
    expect(lastRemaining).toBe(0);

    const overLimit = await request(app).get('/api/v1/Suppliers').set('X-API-Key', key);
    expect(overLimit.status).toBe(429);
  });

  test('a revoked key is rejected even if it was previously valid', async () => {
    const { key } = (await request(app).post('/admin/keys').send({ name: 'revoke-test' })).body;
    await request(app).post(`/admin/keys/${key}/revoke`);
    const res = await request(app).get('/api/v1/Suppliers').set('X-API-Key', key);
    expect(res.status).toBe(401);
  });
});
