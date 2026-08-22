# api-gateway

An API Management simulation in front of `procurement-core`'s OData
service: API-key consumer authentication, per-key rate limiting, and an
API Business Hub-style catalog entry — the governance layer real BTP API
Management provides, gateway-first rather than baked into the app itself.

## What's simulated vs. real SAP API Management

| | This simulation | Real BTP API Management |
|---|---|---|
| Consumer keys | In-memory (`src/api-keys.js`) | A managed consumer/application registry |
| Rate limiting | Fixed-window, per key (`src/rate-limiter.js`) — has a known real quirk noted in that file's comments | Configurable policies, including spike-arrest for exactly that quirk |
| Catalog | Static JSON (`src/catalog.js`) | A real, discoverable API Business Hub entry |
| Backend auth | Transparently forwards the caller's own `Authorization` header — the gateway **adds** a policy layer, it doesn't replace `procurement-core`'s own RBAC | Same principle in practice — API Management is a policy layer, not usually a replacement for the backend's own auth |

## Run it

```bash
npm install
npm start   # listens on :4008, proxies to http://localhost:4004/procurement
```

```bash
# 1. Get a key
curl -X POST http://localhost:4008/admin/keys -d '{"name":"my-app"}' -H 'Content-Type: application/json'

# 2. Use it — Basic Auth still required for whatever procurement-core itself protects
curl -u alice: -H "X-API-Key: <key>" http://localhost:4008/api/v1/Suppliers

# 3. Browse the catalog
curl http://localhost:4008/catalog
```

### Tests

```bash
npm test
```

16/16 passing: pure unit tests for key issuance/revocation and rate
limiting, plus gateway-level tests (auth rejection, rate-limit
enforcement, catalog shape) that don't need `procurement-core` running.

## Two real bugs found by actually running the full chain, not just unit tests

1. **Empty bodies were silently forwarded.** The proxy route applied
   `express.raw()` to capture the request body for forwarding — but the
   global `express.json()` middleware (needed for `/admin/keys`) had
   already consumed the request stream by the time that route ran, so
   `express.raw()` got nothing. Every POST through the gateway (submit,
   approve, sync) was silently sending an empty body, producing `400`s
   where real responses were expected. Fixed by re-serializing the
   already-parsed `req.body` instead of trying to re-read an exhausted
   stream. Caught by actually calling `syncLegacySuppliers` through the
   gateway and getting a `400` where a `401`/`403` was expected — a pure
   unit test with a mocked upstream would never have caught this.
2. **A genuinely more serious one, found one level deeper**: calling
   `syncLegacySuppliers` through the gateway with `legacy-erp-gateway`
   stopped crashed `procurement-core`'s entire server process — an
   unhandled `fetch()` rejection (`ECONNREFUSED`) with no try/catch around
   it. Fixed in `procurement-core/srv/service.js` (see that commit), not
   in this service — the bug was there, this gateway's end-to-end test
   just happened to be what exercised the failure path that finally
   surfaced it. Verified fixed: `procurement-core` now returns a clean
   `502` and stays fully alive when the legacy system is unreachable
   (confirmed by reading `Suppliers` successfully immediately after).

## Known limitations (honesty notes)

- No persistence — API keys and rate-limit counters reset on restart.
- Fixed-window rate limiting can momentarily allow close to 2x the
  nominal rate right at a window boundary — a real, known limitation of
  this algorithm, not fixed here (see `src/rate-limiter.js`'s comment).
- Forwards `Authorization` transparently rather than doing anything with
  it itself — this gateway adds a policy layer, it deliberately doesn't
  attempt to replace or reason about `procurement-core`'s own auth.
