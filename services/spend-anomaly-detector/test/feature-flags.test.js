'use strict';

const featureFlags = require('../src/feature-flags');
const { evaluate } = require('../src/rules');

const roundPO = {
  totalAmount: 15_000,
  currency: 'USD',
  supplier: { ID: 's1', name: 'Test Supplier', riskRating: 'LOW' },
  items: [{ material: 'Widget', quantity: 1, unitPrice: 15_000 }],
};

describe('feature flags — runtime toggle, no restart', () => {
  afterEach(() => {
    featureFlags.setEnabled('ROUND_NUMBER_AMOUNT_RULE', true); // restore default
  });

  test('unknown flag names are rejected, not silently ignored', () => {
    expect(() => featureFlags.isEnabled('NOT_A_REAL_FLAG')).toThrow(/Unknown feature flag/);
    expect(() => featureFlags.setEnabled('NOT_A_REAL_FLAG', true)).toThrow(/Unknown feature flag/);
  });

  test('same PO, same process, flag ON vs OFF — genuinely different rule outcome, no redeploy between', () => {
    featureFlags.setEnabled('ROUND_NUMBER_AMOUNT_RULE', true);
    const withFlagOn = evaluate(roundPO);
    expect(withFlagOn.flags.map((f) => f.rule)).toContain('ROUND_NUMBER_AMOUNT');

    featureFlags.setEnabled('ROUND_NUMBER_AMOUNT_RULE', false);
    const withFlagOff = evaluate(roundPO);
    expect(withFlagOff.flags.map((f) => f.rule)).not.toContain('ROUND_NUMBER_AMOUNT');

    // proves this is a genuine behavior change, not two coincidentally-different PHOs
    expect(withFlagOn.flags.length).toBeGreaterThan(withFlagOff.flags.length);
  });

  test('list() reflects current state', () => {
    featureFlags.setEnabled('ROUND_NUMBER_AMOUNT_RULE', false);
    const flag = featureFlags.list().find((f) => f.name === 'ROUND_NUMBER_AMOUNT_RULE');
    expect(flag.enabled).toBe(false);
  });
});
