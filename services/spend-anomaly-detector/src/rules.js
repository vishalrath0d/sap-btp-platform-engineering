'use strict';

const config = require('./config');

/**
 * Deterministic, explainable rules — not a trained model. Each rule states
 * exactly why it fired, in plain language, because an anomaly review that
 * can't explain itself doesn't get acted on. A real v-next here is a
 * learned/statistical model layered on top of these (e.g. a per-supplier
 * historical baseline instead of a flat threshold) — flagged as a known
 * simplification, not hidden.
 */

/** @param {{material:string, quantity:number, unitPrice:number}[]} items */
function unitPriceOutliers(items) {
  if (items.length < 2) return []; // no "average" worth comparing a single item against
  const avg = items.reduce((sum, i) => sum + Number(i.unitPrice), 0) / items.length;
  if (avg <= 0) return [];
  return items
    .filter((i) => Number(i.unitPrice) > avg * config.unitPriceOutlierMultiple)
    .map((i) => ({
      rule: 'UNIT_PRICE_OUTLIER',
      detail: `"${i.material}" unit price ${i.unitPrice} is more than ${config.unitPriceOutlierMultiple}x this PO's average item price (${avg.toFixed(2)})`,
    }));
}

/**
 * @param {{totalAmount:number, currency:string, supplier?:{ID:string,name?:string,riskRating?:string}, items:Array}} po
 */
function evaluate(po) {
  const flags = [];

  if (po.totalAmount > config.largeOrderThreshold) {
    flags.push({
      rule: 'LARGE_ORDER',
      detail: `Total ${po.totalAmount} ${po.currency} exceeds the single-order review threshold of ${config.largeOrderThreshold}`,
    });
  }

  if (po.supplier?.riskRating === 'HIGH') {
    flags.push({
      rule: 'HIGH_RISK_SUPPLIER',
      detail: `Supplier ${po.supplier.name || po.supplier.ID} is rated HIGH risk (per supplier-risk-assessment-guideline.md, this alone should route to CFO-office notification if the order exceeds $50,000)`,
    });
  }

  // A classic, real spend-analytics heuristic: a suspiciously round total on
  // an itemized order can indicate an estimated or fabricated invoice rather
  // than one built up from real line-item costs.
  if (po.totalAmount >= 1000 && po.totalAmount % 1000 === 0) {
    flags.push({
      rule: 'ROUND_NUMBER_AMOUNT',
      detail: `Total ${po.totalAmount} is an exact multiple of 1000 on an itemized order — worth a sanity check against the line items`,
    });
  }

  flags.push(...unitPriceOutliers(po.items || []));

  const severity = flags.length === 0 ? 'NONE' : flags.length === 1 ? 'LOW' : flags.length === 2 ? 'MEDIUM' : 'HIGH';
  return { flags, severity };
}

module.exports = { evaluate, unitPriceOutliers };
