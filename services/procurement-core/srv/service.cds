using { sap.procureiq as db } from '../db/schema';

type SyncError {
  record : String;
  error  : String;
}

type SyncResult {
  destination  : String;
  totalRecords : Integer;
  created      : Integer;
  updated      : Integer;
  skipped      : Integer;
  errors       : many SyncError;
}

/**
 * ProcurementService is the one API surface for the whole requisition ->
 * approval -> purchase order lifecycle. Suppliers and PurchaseOrders are
 * read-only here on purpose: suppliers are managed elsewhere (a future
 * supplier-onboarding flow, or synced in via syncLegacySuppliers below),
 * and POs only ever come out of approve().
 */
service ProcurementService @(path: '/procurement') {

  @readonly
  entity Suppliers as projection on db.Suppliers;

  /**
   * Pulls supplier master data from the legacy on-prem system through a
   * Destination-service-shaped connectivity layer (srv/lib/destination.js)
   * simulating the Cloud Connector boundary - see
   * docs/concepts/11-connectivity-cloud-connector.md. Idempotent: matches
   * on externalId+sourceSystem, creates new suppliers or updates the
   * fields that can legitimately change (risk rating, status, email).
   */
  @requires: 'IntegrationAdmin'
  action syncLegacySuppliers() returns SyncResult;

  entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
    @requires: 'Requester'
    action submit()                  returns PurchaseRequisitions;

    @requires: 'Approver'
    action approve(comment: String)  returns PurchaseRequisitions;

    @requires: 'Approver'
    action rejectRequisition(comment: String) returns PurchaseRequisitions;
  };

  entity PurchaseRequisitionItems as projection on db.PurchaseRequisitionItems;

  @readonly
  entity Approvals as projection on db.Approvals;

  @readonly
  entity PurchaseOrders as projection on db.PurchaseOrders;

  @readonly
  entity PurchaseOrderItems as projection on db.PurchaseOrderItems;
}
