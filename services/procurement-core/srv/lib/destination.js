'use strict';

const destinations = require('./destinations.json');

/**
 * Shaped like what the real SAP Destination service's `getDestination()`
 * call returns (Name, URL, ProxyType, Authentication) — deliberately not
 * the real `@sap-cloud-sdk/connectivity` package, which needs a live BTP
 * Destination service instance and (for ProxyType: 'OnPremise') an actual
 * Cloud Connector tunnel to resolve through. Neither exists on a laptop.
 *
 * The seam is exactly this function's signature: every caller does
 * `getDestination('LEGACY_SUPPLIER_ERP')` and gets back `{ URL, ... }` to
 * call — swapping this file's body for a real
 * `await connectivity.getDestination('LEGACY_SUPPLIER_ERP')` call later
 * means changing this one file, not any of its callers (see
 * srv/service.js's syncLegacySuppliers handler).
 *
 * ProxyType matters even in simulation: 'OnPremise' is the signal that,
 * for real, this call would be routed through Cloud Connector rather than
 * hitting the public internet directly — a caller could reasonably branch
 * on it (e.g. to decide whether a call is even expected to succeed outside
 * a VPN) even though this simulation doesn't need to.
 */
function getDestination(name) {
  const destination = destinations[name];
  if (!destination) {
    throw new Error(`No destination configured named "${name}" (checked srv/lib/destinations.json)`);
  }
  return destination;
}

module.exports = { getDestination };
