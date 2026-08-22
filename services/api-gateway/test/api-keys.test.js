'use strict';

const apiKeys = require('../src/api-keys');

describe('api-keys', () => {
  test('issued keys are valid', () => {
    const key = apiKeys.issueKey('test-consumer');
    expect(apiKeys.isValid(key)).toBe(true);
    expect(apiKeys.meta(key).name).toBe('test-consumer');
  });

  test('unknown keys are invalid', () => {
    expect(apiKeys.isValid('not-a-real-key')).toBe(false);
  });

  test('a name is required to issue a key', () => {
    expect(() => apiKeys.issueKey()).toThrow(/name is required/);
  });

  test('revoked keys become invalid', () => {
    const key = apiKeys.issueKey('revoke-me');
    expect(apiKeys.isValid(key)).toBe(true);
    apiKeys.revoke(key);
    expect(apiKeys.isValid(key)).toBe(false);
  });

  test('revoking an unknown key throws', () => {
    expect(() => apiKeys.revoke('not-a-real-key')).toThrow(/unknown API key/);
  });

  test('list() never exposes the full key', () => {
    const key = apiKeys.issueKey('list-test');
    const entry = apiKeys.list().find((e) => e.name === 'list-test');
    expect(entry.keyPrefix).toHaveLength(11); // 8 chars + '...'
    expect(entry.keyPrefix).not.toBe(key);
  });
});
