'use strict';

const rateLimiter = require('../src/rate-limiter');
const config = require('../src/config');

describe('rate-limiter', () => {
  beforeEach(() => rateLimiter._resetForTests());

  test('allows requests up to the max within a window', () => {
    const key = 'test-key-1';
    let last;
    for (let i = 0; i < config.rateLimitMax; i++) {
      last = rateLimiter.checkAndIncrement(key, 1000);
      expect(last.allowed).toBe(true);
    }
    expect(last.remaining).toBe(0);
  });

  test('blocks requests beyond the max within the same window', () => {
    const key = 'test-key-2';
    for (let i = 0; i < config.rateLimitMax; i++) {
      rateLimiter.checkAndIncrement(key, 1000);
    }
    const overLimit = rateLimiter.checkAndIncrement(key, 1000);
    expect(overLimit.allowed).toBe(false);
  });

  test('a new window resets the count', () => {
    const key = 'test-key-3';
    for (let i = 0; i < config.rateLimitMax; i++) {
      rateLimiter.checkAndIncrement(key, 1000);
    }
    expect(rateLimiter.checkAndIncrement(key, 1000).allowed).toBe(false);

    const nextWindow = rateLimiter.checkAndIncrement(key, 1000 + config.rateLimitWindowMs + 1);
    expect(nextWindow.allowed).toBe(true);
  });

  test('different keys have independent limits', () => {
    const keyA = 'independent-a';
    const keyB = 'independent-b';
    for (let i = 0; i < config.rateLimitMax; i++) {
      rateLimiter.checkAndIncrement(keyA, 1000);
    }
    expect(rateLimiter.checkAndIncrement(keyA, 1000).allowed).toBe(false);
    expect(rateLimiter.checkAndIncrement(keyB, 1000).allowed).toBe(true);
  });
});
