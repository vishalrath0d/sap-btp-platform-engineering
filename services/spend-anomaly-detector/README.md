# spend-anomaly-detector

An event-driven service that reviews every newly-created Purchase Order for
spend anomalies — large orders, HIGH-risk suppliers, suspiciously round
totals, and outlier line-item pricing — and records an explainable,
rule-by-rule review. Designed to run on **Kyma**, subscribing to a
`PurchaseOrderCreated` event; runs as a plain HTTP webhook receiver locally.

**Currently deployed to Cloud Foundry temporarily** (`manifest.yml`, via
`cf-deploy.yml`), not Kyma — this trial account has no self-service Kyma
provisioning at all (confirmed live, twice over), and a trial Kyma cluster
request is pending SAP's approval (see `infra/terraform/modules/kyma-env/
main.tf` and `docs/next/next.md`). The app itself is unchanged either way;
what's genuinely missing on CF is the gateway-level JWT auth the real Kyma
path enforces via `APIRule` against the XSUAA instance in `k8s/` — this
service's webhook is open/unauthenticated on CF, the same posture it
already has in local Docker Compose testing. The `k8s/` manifests and
`kyma-deploy.yml`/`piper-kyma-deploy.yml` are untouched and become the
real deploy path again the moment SAP approves the request.

## Why HTTP locally, not a real event broker

Production topology: `procurement-core` (Cloud Foundry) publishes
`PurchaseOrderCreated` to **SAP Event Mesh**; this service (Kyma) subscribes
to it via AMQP. Locally, standing up a message broker just to demo one event
type didn't seem worth the added moving parts — so `procurement-core`'s
`srv/lib/events.js` instead does a plain HTTP POST to this service's
`/events/purchase-order-created` endpoint after a Purchase Order is created.

**The important design property carries over regardless of transport**:
publishing never blocks or fails PO creation. If this service is down,
`procurement-core`'s `approve()` still succeeds — it logs a warning and
moves on (verified: `procurement-core`'s own test suite passes with this
service not running at all). That's exactly how a real pub/sub publish
behaves from the producer's side, and it's the property that matters, not
which specific transport is under it today.

## The rules (deterministic and explainable, not a trained model)

| Rule | Fires when |
|---|---|
| `LARGE_ORDER` | Total exceeds `LARGE_ORDER_THRESHOLD` (default $30,000) |
| `HIGH_RISK_SUPPLIER` | The supplier's `riskRating` is `HIGH` |
| `ROUND_NUMBER_AMOUNT` | Total is an exact multiple of 1000 — a real, commonly-used spend-analytics heuristic: an itemized order landing on a suspiciously round number can indicate an estimated invoice rather than one built from real line-item costs |
| `UNIT_PRICE_OUTLIER` | Any single item's unit price is more than `UNIT_PRICE_OUTLIER_MULTIPLE`x (default 3x) the PO's own average unit price |

Severity is just the flag count: 0 → `NONE`, 1 → `LOW`, 2 → `MEDIUM`, 3+ →
`HIGH`. See `src/rules.js` for the actual (short, readable) implementation —
a real v-next would replace the flat thresholds with a per-supplier
historical baseline; documented as a known simplification, not hidden.

## Run it

```bash
npm install
npm start   # listens on :4006
```

Exercised for real against a running `procurement-core` (see repo root for
how to start both): approving a normal $15,200 PO against a MEDIUM-risk
supplier produced a `NONE`-severity, zero-flag review; approving a $65,000
PO against a HIGH-risk supplier produced a `HIGH`-severity review with
`LARGE_ORDER`, `HIGH_RISK_SUPPLIER`, and `ROUND_NUMBER_AMOUNT` all correctly
firing — not asserted, actually run and checked via `GET /anomalies`.

```bash
curl http://localhost:4006/anomalies                    # all reviews, newest first
curl http://localhost:4006/anomalies?flaggedOnly=true    # only the ones with >=1 flag
curl http://localhost:4006/anomalies/PO-00003             # one review in full
```

### Tests

```bash
npm test
```

13/13 passing — pure rule-logic unit tests plus HTTP API tests (no
`procurement-core` needed to run these; they post synthetic PO payloads
directly). One real bug caught while writing the unit tests, not the
service code: a test asserted a single extreme-priced item would always be
flagged as a `UNIT_PRICE_OUTLIER`, but with too few "normal" items in the
fixture, the outlier's own price pulled the average high enough to clear
its own 3x threshold — a real, worth-knowing property of mean-based outlier
detection, not a bug in `rules.js`. Fixed by using a fixture with enough
normal-priced items that the average stays representative — documented
inline in the test.

## Known limitations (honesty notes)

- Flat thresholds, not per-supplier or per-category historical baselines —
  a $30,000 order is "large" for every supplier and every material category
  alike right now, which isn't how a mature spend-analytics system would
  work.
- No de-duplication or re-evaluation: if the same `poNumber` were ever
  re-submitted, the review is simply overwritten, not versioned.
- In-memory + JSONL storage only, no real database — fine for this project's
  scale, not for production volume.
