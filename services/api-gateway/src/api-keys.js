'use strict';

const crypto = require('crypto');

// In-memory API key store - simulates SAP API Management's consumer/
// application key issuance. Real API Management ties a key to a
// registered "application" with subscribed API products; this is the
// minimal slice of that (a name + active flag) needed to demonstrate the
// actual gateway behavior (auth + rate limiting), not a full consumer-
// management product.
const keys = new Map(); // key -> { name, createdAt, active }

function issueKey(name) {
  if (!name) throw new Error('a consumer name is required to issue an API key');
  const key = crypto.randomBytes(24).toString('hex');
  keys.set(key, { name, createdAt: Date.now(), active: true });
  return key;
}

function isValid(key) {
  const entry = keys.get(key);
  return Boolean(entry && entry.active);
}

function meta(key) {
  return keys.get(key) || null;
}

function revoke(key) {
  const entry = keys.get(key);
  if (!entry) throw new Error(`unknown API key`);
  entry.active = false;
}

function list() {
  return [...keys.entries()].map(([key, v]) => ({ keyPrefix: key.slice(0, 8) + '...', ...v }));
}

module.exports = { issueKey, isValid, meta, revoke, list };
