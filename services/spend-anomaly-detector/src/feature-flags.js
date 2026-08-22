'use strict';

/**
 * Simulates SAP's Feature Flags service — a bound BTP service that lets an
 * app toggle behavior at runtime without a redeploy, via an admin UI/API
 * rather than an env var + restart. The real service's Node client polls
 * (or subscribes to) the bound service instance for flag state; this
 * simulation keeps flags in memory with the exact same read surface
 * (`isEnabled(name)`), so the only thing that changes when wiring up the
 * real service later is what's behind that one function.
 *
 * Deliberately in-memory, not env-var-driven — the whole point of a
 * feature-flag service is changing behavior *without* a restart, which an
 * env var can't do. See test/feature-flags.test.js for a same-process
 * before/after toggle proving this.
 */

const flags = new Map([
  // [name, { enabled, description }]
  ['ROUND_NUMBER_AMOUNT_RULE', { enabled: true, description: 'Flag POs with a suspiciously round total' }],
]);

function isEnabled(name) {
  const flag = flags.get(name);
  if (!flag) throw new Error(`Unknown feature flag "${name}"`);
  return flag.enabled;
}

function setEnabled(name, enabled) {
  const flag = flags.get(name);
  if (!flag) throw new Error(`Unknown feature flag "${name}"`);
  flag.enabled = Boolean(enabled);
  return { name, ...flag };
}

function list() {
  return [...flags.entries()].map(([name, flag]) => ({ name, ...flag }));
}

module.exports = { isEnabled, setEnabled, list };
