'use strict';

// Pure, network-free mapping from the legacy system's shape to ProcureIQ's
// domain model — real integration-developer work, not incidental plumbing.
// Kept as a pure function specifically so it's unit-testable without
// legacy-erp-gateway needing to be running (see test/legacy-supplier-mapper.test.js).

const RISK_MAP = { L: 'LOW', M: 'MEDIUM', H: 'HIGH' };
const STATUS_MAP = { A: 'ACTIVE', I: 'INACTIVE', B: 'BLOCKED' };

const SOURCE_SYSTEM = 'LEGACY_SUPPLIER_ERP';

/**
 * @param {{SUPPLIER_ID:string, COMPANY_NAME:string, CTRY_CD:string, TAX_REG_NO:string, CONTACT_EMAIL:string, RISK_CD:string, REC_STATUS:string}} record
 */
function mapLegacySupplier(record) {
  const riskRating = RISK_MAP[record.RISK_CD];
  const status = STATUS_MAP[record.REC_STATUS];

  if (!riskRating) throw new Error(`Unknown legacy RISK_CD "${record.RISK_CD}" for supplier ${record.SUPPLIER_ID}`);
  if (!status) throw new Error(`Unknown legacy REC_STATUS "${record.REC_STATUS}" for supplier ${record.SUPPLIER_ID}`);
  if (!record.SUPPLIER_ID) throw new Error('Legacy record is missing SUPPLIER_ID');

  return {
    externalId: record.SUPPLIER_ID,
    sourceSystem: SOURCE_SYSTEM,
    name: record.COMPANY_NAME,
    country: record.CTRY_CD,
    taxId: record.TAX_REG_NO,
    email: record.CONTACT_EMAIL,
    riskRating,
    status,
  };
}

module.exports = { mapLegacySupplier, SOURCE_SYSTEM, RISK_MAP, STATUS_MAP };
