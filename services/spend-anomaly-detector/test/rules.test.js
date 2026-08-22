'use strict';

const { evaluate, unitPriceOutliers } = require('../src/rules');

const cleanPO = {
  totalAmount: 8400,
  currency: 'USD',
  supplier: { ID: 's1', name: 'Acme Components Ltd', riskRating: 'LOW' },
  items: [
    { material: 'PLC Module CPU-1215C', quantity: 4, unitPrice: 1450 },
    { material: 'PLC Digital I/O Module DI16', quantity: 8, unitPrice: 325 },
  ],
};

describe('evaluate', () => {
  test('a normal PO triggers no flags and severity NONE', () => {
    const { flags, severity } = evaluate(cleanPO);
    expect(flags).toHaveLength(0);
    expect(severity).toBe('NONE');
  });

  test('LARGE_ORDER fires above the threshold', () => {
    const { flags, severity } = evaluate({ ...cleanPO, totalAmount: 45_000 });
    expect(flags.map((f) => f.rule)).toContain('LARGE_ORDER');
    expect(severity).not.toBe('NONE');
  });

  test('HIGH_RISK_SUPPLIER fires only for HIGH risk rating', () => {
    const high = evaluate({ ...cleanPO, supplier: { ...cleanPO.supplier, riskRating: 'HIGH' } });
    expect(high.flags.map((f) => f.rule)).toContain('HIGH_RISK_SUPPLIER');

    const medium = evaluate({ ...cleanPO, supplier: { ...cleanPO.supplier, riskRating: 'MEDIUM' } });
    expect(medium.flags.map((f) => f.rule)).not.toContain('HIGH_RISK_SUPPLIER');
  });

  test('ROUND_NUMBER_AMOUNT fires on an exact multiple of 1000, not on a normal total', () => {
    expect(evaluate({ ...cleanPO, totalAmount: 15_000 }).flags.map((f) => f.rule)).toContain('ROUND_NUMBER_AMOUNT');
    expect(evaluate({ ...cleanPO, totalAmount: 8400 }).flags.map((f) => f.rule)).not.toContain('ROUND_NUMBER_AMOUNT');
  });

  test('multiple simultaneous flags raise severity to MEDIUM/HIGH', () => {
    const bad = evaluate({
      ...cleanPO,
      totalAmount: 60_000,
      supplier: { ...cleanPO.supplier, riskRating: 'HIGH' },
    });
    expect(bad.flags.length).toBeGreaterThanOrEqual(2);
    expect(['MEDIUM', 'HIGH']).toContain(bad.severity);
  });
});

describe('unitPriceOutliers', () => {
  test('flags an item priced far above the PO average', () => {
    // Deliberately several "normal" items so the one outlier doesn't skew
    // the average enough to hide itself (a single [2, 3, 500] set doesn't
    // trigger this: the outlier pulls its own 3x-average threshold up past
    // its own price — a real property of mean-based outlier detection,
    // caught by first writing this test wrong and checking the arithmetic).
    const items = [
      { material: 'Standard bolt', quantity: 100, unitPrice: 2 },
      { material: 'Standard bracket', quantity: 50, unitPrice: 3 },
      { material: 'Standard washer', quantity: 200, unitPrice: 2 },
      { material: 'Standard nut', quantity: 200, unitPrice: 3 },
      { material: 'Mystery custom part', quantity: 1, unitPrice: 500 },
    ];
    const outliers = unitPriceOutliers(items);
    expect(outliers).toHaveLength(1);
    expect(outliers[0].detail).toContain('Mystery custom part');
  });

  test('does not flag anything when prices are close together', () => {
    const items = [
      { material: 'A', quantity: 1, unitPrice: 10 },
      { material: 'B', quantity: 1, unitPrice: 11 },
      { material: 'C', quantity: 1, unitPrice: 9 },
    ];
    expect(unitPriceOutliers(items)).toHaveLength(0);
  });

  test('a single-item PO has nothing to compare against, so it is never flagged', () => {
    expect(unitPriceOutliers([{ material: 'Solo item', quantity: 1, unitPrice: 999_999 }])).toHaveLength(0);
  });
});
