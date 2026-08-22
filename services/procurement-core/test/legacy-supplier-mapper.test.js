'use strict';

const { mapLegacySupplier } = require('../srv/lib/legacy-supplier-mapper');

const validRecord = {
  SUPPLIER_ID: 'LEG-001',
  COMPANY_NAME: 'Meridian Fabrication Works',
  CTRY_CD: 'US',
  TAX_REG_NO: 'US-TAX-778',
  CONTACT_EMAIL: 'ap@meridianfab.example',
  RISK_CD: 'L',
  REC_STATUS: 'A',
};

describe('mapLegacySupplier', () => {
  test('maps a valid legacy record to the domain shape', () => {
    const mapped = mapLegacySupplier(validRecord);
    expect(mapped).toEqual({
      externalId: 'LEG-001',
      sourceSystem: 'LEGACY_SUPPLIER_ERP',
      name: 'Meridian Fabrication Works',
      country: 'US',
      taxId: 'US-TAX-778',
      email: 'ap@meridianfab.example',
      riskRating: 'LOW',
      status: 'ACTIVE',
    });
  });

  test.each([
    ['M', 'MEDIUM'],
    ['H', 'HIGH'],
  ])('maps RISK_CD %s to %s', (code, expected) => {
    expect(mapLegacySupplier({ ...validRecord, RISK_CD: code }).riskRating).toBe(expected);
  });

  test.each([
    ['I', 'INACTIVE'],
    ['B', 'BLOCKED'],
  ])('maps REC_STATUS %s to %s', (code, expected) => {
    expect(mapLegacySupplier({ ...validRecord, REC_STATUS: code }).status).toBe(expected);
  });

  test('rejects an unknown risk code instead of guessing', () => {
    expect(() => mapLegacySupplier({ ...validRecord, RISK_CD: 'X' })).toThrow(/Unknown legacy RISK_CD/);
  });

  test('rejects an unknown status code instead of guessing', () => {
    expect(() => mapLegacySupplier({ ...validRecord, REC_STATUS: 'X' })).toThrow(/Unknown legacy REC_STATUS/);
  });

  test('rejects a record with no SUPPLIER_ID', () => {
    expect(() => mapLegacySupplier({ ...validRecord, SUPPLIER_ID: undefined })).toThrow(/missing SUPPLIER_ID/);
  });
});
