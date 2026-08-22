'use strict';

const express = require('express');
const config = require('./config');
const apiKeys = require('./api-keys');
const rateLimiter = require('./rate-limiter');
const catalog = require('./catalog');

function requireApiKey(req, res, next) {
  const key = req.header('X-API-Key');
  if (!key || !apiKeys.isValid(key)) {
    return res.status(401).json({ error: 'missing or invalid X-API-Key header' });
  }

  const { allowed, remaining, resetAt } = rateLimiter.checkAndIncrement(key);
  res.set('X-RateLimit-Remaining', String(remaining));
  res.set('X-RateLimit-Reset', String(resetAt));
  if (!allowed) {
    return res.status(429).json({ error: 'rate limit exceeded', resetAt });
  }

  req.apiKeyMeta = apiKeys.meta(key);
  next();
}

function createApp() {
  const app = express();
  app.use(express.json());

  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.get('/catalog', (req, res) => res.json(catalog));

  // Consumer onboarding - simulates registering an application against an
  // API product in API Business Hub / API Management. No auth of its own
  // on purpose: this is the "get a key" step every other endpoint then
  // requires a key for.
  app.post('/admin/keys', (req, res) => {
    try {
      const key = apiKeys.issueKey(req.body?.name);
      res.status(201).json({ key, name: req.body.name });
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  });

  app.post('/admin/keys/:key/revoke', (req, res) => {
    try {
      apiKeys.revoke(req.params.key);
      res.json({ revoked: true });
    } catch (err) {
      res.status(404).json({ error: err.message });
    }
  });

  // The actual gateway: API-key-gated, rate-limited, transparent proxy to
  // procurement-core. Forwards the caller's Authorization header
  // unchanged - the gateway ADDS a policy layer, it doesn't replace
  // procurement-core's own RBAC (see catalog.js's authentication.note).
  //
  // Re-serializes req.body rather than forwarding raw bytes: the global
  // express.json() above already consumed and parsed the request stream,
  // so by the time this route runs there are no raw bytes left to forward
  // - a real bug hit while testing this live (empty bodies were reaching
  // procurement-core, producing 400s where 401/403 were expected), fixed
  // by re-stringifying the already-parsed body instead of trying to
  // re-read an exhausted stream.
  app.use('/api/v1', requireApiKey, async (req, res) => {
    const targetPath = req.originalUrl.replace(/^\/api\/v1/, '');
    const targetUrl = `${config.procurementCoreUrl}${targetPath}`;
    const hasBody = !['GET', 'HEAD'].includes(req.method) && req.body && Object.keys(req.body).length > 0;

    try {
      const upstream = await fetch(targetUrl, {
        method: req.method,
        headers: {
          'Content-Type': 'application/json',
          ...(req.header('Authorization') ? { Authorization: req.header('Authorization') } : {}),
        },
        body: hasBody ? JSON.stringify(req.body) : undefined,
        signal: AbortSignal.timeout(5000),
      });

      const text = await upstream.text();
      res.status(upstream.status);
      res.set('Content-Type', upstream.headers.get('content-type') || 'application/json');
      res.send(text);
    } catch (err) {
      res.status(502).json({ error: `procurement-core unreachable: ${err.message}` });
    }
  });

  return app;
}

if (require.main === module) {
  createApp().listen(config.port, () => {
    console.log(`[api-gateway] listening on http://localhost:${config.port}, proxying to ${config.procurementCoreUrl}`);
  });
}

module.exports = { createApp };
