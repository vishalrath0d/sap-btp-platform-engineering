using { sap.procureiq as db } from '../db/schema';

/**
 * ProcurementService is the one API surface for the whole requisition ->
 * approval -> purchase order lifecycle. Suppliers and PurchaseOrders are
 * read-only here on purpose: suppliers are managed elsewhere (a future
 * supplier-onboarding flow), and POs only ever come out of approve().
 */
service ProcurementService @(path: '/procurement') {

  @readonly
  entity Suppliers as projection on db.Suppliers;

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
