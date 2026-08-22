'use strict';

/**
 * Threshold table deciding who has to approve a requisition, based on its
 * total amount at submit time. Deliberately a flat, readable table instead
 * of a rules engine — this is the kind of decision a real procurement org
 * documents in one page, and the code should read the same way.
 */
const THRESHOLDS = [
  { limit: 10_000, role: 'MANAGER' },
  { limit: 50_000, role: 'DIRECTOR' },
  { limit: Infinity, role: 'CFO' },
];

/** @param {number} amount @returns {'MANAGER'|'DIRECTOR'|'CFO'} */
function approverRoleFor(amount) {
  const tier = THRESHOLDS.find((t) => amount <= t.limit);
  return tier.role;
}

module.exports = { approverRoleFor, THRESHOLDS };
