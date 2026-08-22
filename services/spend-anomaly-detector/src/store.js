'use strict';

const fs = require('fs');
const path = require('path');
const config = require('./config');

// In-memory review log, plus append-only JSONL for durability across
// restarts (data/anomalies.jsonl, gitignored - it's runtime data).
const reviews = new Map(); // poNumber -> review record

function record(poNumber, review) {
  const entry = { poNumber, receivedAt: Date.now(), ...review };
  reviews.set(poNumber, entry);
  fs.mkdirSync(path.dirname(config.anomaliesFile), { recursive: true });
  fs.appendFileSync(config.anomaliesFile, JSON.stringify(entry) + '\n');
  return entry;
}

function get(poNumber) {
  return reviews.get(poNumber) || null;
}

function list({ flaggedOnly = false, limit = 50 } = {}) {
  return [...reviews.values()]
    .filter((r) => !flaggedOnly || r.severity !== 'NONE')
    .sort((a, b) => b.receivedAt - a.receivedAt)
    .slice(0, limit);
}

function listSince(timestamp, { severity } = {}) {
  return [...reviews.values()]
    .filter((r) => r.receivedAt > timestamp)
    .filter((r) => !severity || r.severity === severity)
    .sort((a, b) => a.receivedAt - b.receivedAt);
}

module.exports = { record, get, list, listSince };
