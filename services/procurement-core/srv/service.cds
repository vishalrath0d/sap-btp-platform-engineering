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
// `requires: 'any'` HERE, at the service level, is the real fix for a
// second real bug hit live deploying this: CAP's own HTTP adapter
// (node_modules/@sap/cds/lib/srv/protocols/http.js) applies a SEPARATE,
// SERVICE-WIDE gate ahead of any entity/action-level @requires or
// @restrict - in production (NODE_ENV=production, true on CF, false
// locally - confirmed by reading that file directly) it defaults EVERY
// service to requiring 'authenticated-user' unless the SERVICE ITSELF
// opts out via this exact annotation. The entity-level @restrict/
// @requires below were real and correctly configured the whole time
// (verified locally, and still work below) - they just never got a
// chance to run, because this outer, service-level gate rejected
// anonymous requests first, with a plain 401, before CDS's own
// finer-grained authorization was ever consulted. This is exactly why
// it worked locally (that outer gate is inactive outside production)
// and 401'd on the real deployed instance - a genuinely environment-
// dependent bug, not a logic error in the per-entity rules themselves.
service ProcurementService @(path: '/procurement', requires: 'any') {

  // Public reads on purpose (requested explicitly, not a default): this
  // project's deployed Fiori preview UI (services/procurement-core/
  // README.md) is meant to be a shareable, cold-open link - a visitor
  // with no BTP login should see real data immediately. Every mutating
  // path stays exactly as protected as before: CREATE/UPDATE/DELETE
  // still need a real authenticated user, not 'any' - only READ is
  // opened up. @readonly entities have no write surface to restrict at
  // all, so those just get a plain @requires: 'any' instead of the
  // more elaborate @restrict form.
  //
  // Real bug hit live testing this: once @restrict is added to an
  // entity, it becomes the EXHAUSTIVE authorization list for that
  // entity - a bound action's own separate @requires annotation
  // stopped being consulted at all once PurchaseRequisitions gained a
  // @restrict block, and every action 403'd even for a correctly-
  // roled user (confirmed live: alice/Requester got 403 on submit(),
  // bob/Approver got 403 on approve()). Fixed by folding each action's
  // requirement into the SAME @restrict list as an explicit grant,
  // rather than leaving them as separate @requires annotations
  // alongside it.

  @readonly
  @requires: 'any'
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

  @restrict: [
    { grant: 'READ', to: 'any' },
    { grant: ['CREATE', 'UPDATE', 'DELETE'], to: 'authenticated-user' },
    { grant: 'submit', to: 'Requester' },
    { grant: 'approve', to: 'Approver' },
    { grant: 'rejectRequisition', to: 'Approver' },
  ]
  entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
    action submit()                  returns PurchaseRequisitions;
    action approve(comment: String)  returns PurchaseRequisitions;
    action rejectRequisition(comment: String) returns PurchaseRequisitions;
  };

  @restrict: [
    { grant: 'READ', to: 'any' },
    { grant: ['CREATE', 'UPDATE', 'DELETE'], to: 'authenticated-user' },
  ]
  entity PurchaseRequisitionItems as projection on db.PurchaseRequisitionItems;

  @readonly
  @requires: 'any'
  entity Approvals as projection on db.Approvals;

  @readonly
  @requires: 'any'
  entity PurchaseOrders as projection on db.PurchaseOrders;

  @readonly
  @requires: 'any'
  entity PurchaseOrderItems as projection on db.PurchaseOrderItems;
}
