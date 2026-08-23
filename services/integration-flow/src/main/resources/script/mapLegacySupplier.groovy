/*
 * SAP Cloud Integration Groovy Script step - the same transformation
 * procurement-core/srv/lib/legacy-supplier-mapper.js already performs
 * locally and has real Jest tests for (see that file's test/
 * legacy-supplier-mapper.test.js) - this is a 1:1 port of the same
 * mapping decisions (RISK_MAP, STATUS_MAP, field names, error cases),
 * not new logic invented for this artifact. See this folder's README for
 * exactly what "verified" means for this file (the mapping *decisions*
 * are proven correct by the JS version's tests; this Groovy port itself
 * has not been run against a live Groovy runtime in this environment).
 *
 * Standard SAP CPI Groovy Script step signature: processData(Message) ->
 * Message. The message body arriving here is the raw JSON array
 * legacy-erp-gateway's GET /legacy/suppliers returns; this script's job
 * is only the transformation, same separation of concerns
 * legacy-supplier-mapper.js keeps as a pure function.
 */

import com.sap.gateway.ip.core.customdev.util.Message
import groovy.json.JsonSlurper
import groovy.json.JsonBuilder

def RISK_MAP = [L: 'LOW', M: 'MEDIUM', H: 'HIGH']
def STATUS_MAP = [A: 'ACTIVE', I: 'INACTIVE', B: 'BLOCKED']
def SOURCE_SYSTEM = 'LEGACY_SUPPLIER_ERP'

Message processData(Message message) {
    def body = message.getBody(String)
    def legacyRecords = new JsonSlurper().parseText(body)

    def mapped = []
    def errors = []

    legacyRecords.each { record ->
        try {
            mapped << mapOne(record, RISK_MAP, STATUS_MAP, SOURCE_SYSTEM)
        } catch (IllegalArgumentException e) {
            // Same "skip and record, don't fail the whole batch" posture
            // procurement-core/srv/service.js's syncLegacySuppliers keeps
            // for a bad individual record.
            errors << [record: record.SUPPLIER_ID ?: '(unknown)', error: e.message]
        }
    }

    message.setHeader('mappingErrorCount', errors.size())
    message.setBody(new JsonBuilder([suppliers: mapped, errors: errors]).toString())
    return message
}

def mapOne(record, riskMap, statusMap, sourceSystem) {
    def riskRating = riskMap[record.RISK_CD]
    def status = statusMap[record.REC_STATUS]

    if (!record.SUPPLIER_ID) {
        throw new IllegalArgumentException('Legacy record is missing SUPPLIER_ID')
    }
    if (!riskRating) {
        throw new IllegalArgumentException("Unknown legacy RISK_CD \"${record.RISK_CD}\" for supplier ${record.SUPPLIER_ID}")
    }
    if (!status) {
        throw new IllegalArgumentException("Unknown legacy REC_STATUS \"${record.REC_STATUS}\" for supplier ${record.SUPPLIER_ID}")
    }

    return [
        externalId  : record.SUPPLIER_ID,
        sourceSystem: sourceSystem,
        name        : record.COMPANY_NAME,
        country     : record.CTRY_CD,
        taxId       : record.TAX_REG_NO,
        email       : record.CONTACT_EMAIL,
        riskRating  : riskRating,
        status      : status,
    ]
}
