'use strict';

const config = require('./config');

// Fixed-window rate limiting, per API key - simulates one of SAP API
// Management's core policies. Fixed-window (not sliding/token-bucket) is
// a deliberate simplicity choice: it has a known real quirk (a burst
// right at a window boundary can momentarily allow ~2x the nominal rate)
// which is worth knowing about rather than silently glossing over -
// real API Management typically offers a spike-arrest policy specifically
// to address this class of problem, which this simulation doesn't attempt.
const windows = new Map(); // key -> { count, windowStart }

function checkAndIncrement(key, now = Date.now()) {
  let w = windows.get(key);
  if (!w || now - w.windowStart >= config.rateLimitWindowMs) {
    w = { count: 0, windowStart: now };
    windows.set(key, w);
  }
  w.count++;
  return {
    allowed: w.count <= config.rateLimitMax,
    remaining: Math.max(0, config.rateLimitMax - w.count),
    resetAt: w.windowStart + config.rateLimitWindowMs,
  };
}

function _resetForTests() {
  windows.clear();
}

module.exports = { checkAndIncrement, _resetForTests };
