'use strict';

/**
 * Publishes PurchaseOrderCreated. In production this becomes an actual
 * SAP Event Mesh publish from Cloud Foundry, consumed by
 * spend-anomaly-detector's Kyma-side subscription — the payload shape and
 * the fact that PO creation NEVER blocks on the consumer being reachable
 * both carry over unchanged; only the transport (HTTP webhook here, AMQP
 * topic there) differs. See services/spend-anomaly-detector/README.md for
 * the other half of this story.
 */

const TARGET_URL = process.env.SPEND_ANOMALY_DETECTOR_URL || 'http://localhost:4006/events/purchase-order-created';

async function publishPurchaseOrderCreated(payload) {
  try {
    const res = await fetch(TARGET_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(2000),
    });
    if (!res.ok) {
      console.warn(`[events] spend-anomaly-detector responded ${res.status} for PO ${payload.poNumber}`);
    }
  } catch (err) {
    // Deliberate: a downstream consumer being unreachable must never fail
    // the PO creation transaction that already committed. Logged, not
    // thrown — matches how a real pub/sub publish (fire-and-forget from
    // the producer's perspective) behaves.
    console.warn(`[events] could not reach spend-anomaly-detector (${err.message}) - PO ${payload.poNumber} was still created`);
  }
}

module.exports = { publishPurchaseOrderCreated };
