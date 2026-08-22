namespace sap.procureiq;

using { cuid, managed } from '@sap/cds/common';

/**
 * A supplier that can be assigned to a requisition and, once a requisition
 * converts, receives a Purchase Order. Kept deliberately simple for v1 —
 * no multi-currency banking details, no supplier scoreccard history yet.
 * riskRating is a manual field today; Phase 4 (ai-copilot) is what makes
 * this a computed/AI-assisted value instead of a guess.
 */
entity Suppliers : cuid, managed {
  name           : String(120) not null;
  country        : String(2)   not null;  // ISO 3166-1 alpha-2
  taxId          : String(40);
  email          : String(120);
  riskRating     : String(6) enum { LOW; MEDIUM; HIGH } default 'MEDIUM';
  status         : String(10) enum { ACTIVE; INACTIVE; BLOCKED } default 'ACTIVE';
  // Provenance for suppliers synced in from an external system (see
  // srv/lib/legacy-supplier-mapper.js) — null for suppliers created
  // directly in ProcureIQ. externalId + sourceSystem together are how
  // syncLegacySuppliers() decides create-vs-update idempotently.
  externalId     : String(40);
  sourceSystem   : String(30);
  purchaseOrders : Association to many PurchaseOrders on purchaseOrders.supplier = $self;
}

/**
 * The requisition lifecycle is the core of this service:
 *   DRAFT -> SUBMITTED -> APPROVED -> CONVERTED   (happy path)
 *   DRAFT -> SUBMITTED -> REJECTED                (rejected path)
 * totalAmount is intentionally left at 0 while DRAFT — it's computed and
 * frozen at submit time from the current item amounts, not live-derived,
 * because that's what actually happens in a real approval workflow: the
 * amount that was approved is the amount on record, even if items are
 * edited afterwards (which submit() blocks anyway).
 */
entity PurchaseRequisitions : cuid, managed {
  requisitionNumber : String(20) @readonly; // assigned server-side on create, e.g. PR-00001
  description        : String(200) not null;
  requestedBy        : String(80) not null;
  department         : String(60);
  status             : String(10) enum { DRAFT; SUBMITTED; APPROVED; REJECTED; CONVERTED } default 'DRAFT';
  currency           : String(3) default 'USD';
  totalAmount        : Decimal(15,2) default 0;
  supplier           : Association to Suppliers;
  items              : Composition of many PurchaseRequisitionItems on items.requisition = $self;
  approvals          : Association to many Approvals on approvals.requisition = $self;
  purchaseOrder      : Association to one PurchaseOrders;
}

entity PurchaseRequisitionItems : cuid {
  requisition : Association to PurchaseRequisitions;
  material    : String(120) not null;
  quantity    : Integer not null;
  unitPrice   : Decimal(15,2) not null;
  amount      : Decimal(15,2); // = quantity * unitPrice, computed server-side on write
}

/**
 * One Approval row per requisition submission. approverRole is decided by
 * srv/lib/approval-rules.js purely from the requisition's total at submit
 * time — a simple, auditable threshold table rather than a hidden rule.
 */
entity Approvals : cuid, managed {
  requisition  : Association to PurchaseRequisitions not null;
  approverRole : String(20) enum { MANAGER; DIRECTOR; CFO } not null;
  status       : String(10) enum { PENDING; APPROVED; REJECTED } default 'PENDING';
  comment      : String(500);
  decidedBy    : String(80);
  decidedAt    : DateTime;
}

/**
 * Never created directly through the API — only ever produced by
 * PurchaseRequisitions.approve(), copying items 1:1 from the source
 * requisition. That's deliberate: a PO here always traces back to an
 * approved requisition, matching how procurement audits actually work.
 */
entity PurchaseOrders : cuid, managed {
  poNumber          : String(20) @readonly;
  supplier          : Association to Suppliers not null;
  sourceRequisition : Association to PurchaseRequisitions;
  status            : String(12) enum { DRAFT; SENT; ACKNOWLEDGED; DELIVERED; COMPLETED; CANCELLED } default 'DRAFT';
  currency          : String(3) default 'USD';
  totalAmount       : Decimal(15,2) default 0;
  items             : Composition of many PurchaseOrderItems on items.purchaseOrder = $self;
}

entity PurchaseOrderItems : cuid {
  purchaseOrder : Association to PurchaseOrders;
  material      : String(120) not null;
  quantity      : Integer not null;
  unitPrice     : Decimal(15,2) not null;
  amount        : Decimal(15,2);
}
