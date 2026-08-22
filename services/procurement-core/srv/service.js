'use strict';

const cds = require('@sap/cds');
const { approverRoleFor } = require('./lib/approval-rules');
const { nextNumber } = require('./lib/sequence');

module.exports = cds.service.impl(async function () {
  const {
    PurchaseRequisitions,
    PurchaseRequisitionItems,
    Approvals,
    PurchaseOrders,
    PurchaseOrderItems,
  } = this.entities;

  // -- document numbering & derived amounts --------------------------------

  this.before('CREATE', PurchaseRequisitions, async (req) => {
    req.data.requisitionNumber = await nextNumber(PurchaseRequisitions, 'PR');
  });

  this.before(['CREATE', 'UPDATE'], PurchaseRequisitionItems, (req) => {
    const { quantity, unitPrice } = req.data;
    if (quantity != null && unitPrice != null) {
      req.data.amount = Number(quantity) * Number(unitPrice);
    }
  });

  // -- submit: DRAFT -> SUBMITTED, opens an Approval -----------------------

  this.on('submit', PurchaseRequisitions, async (req) => {
    const id = req.params[0].ID ?? req.params[0];
    const pr = await SELECT.one
      .from(PurchaseRequisitions, id)
      .columns((p) => {
        p('*'), p.items((i) => i('*'));
      });

    if (!pr) return req.error(404, `Requisition ${id} not found`);
    if (pr.status !== 'DRAFT') {
      return req.error(400, `Requisition ${pr.requisitionNumber} is ${pr.status}, not DRAFT — only a draft requisition can be submitted`);
    }
    if (!pr.items || pr.items.length === 0) {
      return req.error(400, `Requisition ${pr.requisitionNumber} has no line items — add at least one item before submitting`);
    }

    const total = pr.items.reduce((sum, i) => sum + Number(i.amount ?? Number(i.quantity) * Number(i.unitPrice)), 0);
    const approverRole = approverRoleFor(total);

    await UPDATE(PurchaseRequisitions, id).with({ status: 'SUBMITTED', totalAmount: total });
    await INSERT.into(Approvals).entries({
      requisition_ID: id,
      approverRole,
      status: 'PENDING',
    });

    return SELECT.one.from(PurchaseRequisitions, id);
  });

  // -- approve: SUBMITTED -> APPROVED -> CONVERTED, creates the PO --------

  this.on('approve', PurchaseRequisitions, async (req) => {
    const id = req.params[0].ID ?? req.params[0];
    const { comment } = req.data;

    const pr = await SELECT.one.from(PurchaseRequisitions, id);
    if (!pr) return req.error(404, `Requisition ${id} not found`);
    if (pr.status !== 'SUBMITTED') {
      return req.error(400, `Requisition ${pr.requisitionNumber} is ${pr.status} — only a SUBMITTED requisition can be approved`);
    }

    const approval = await SELECT.one.from(Approvals).where({ requisition_ID: id, status: 'PENDING' });
    if (!approval) {
      return req.error(400, `Requisition ${pr.requisitionNumber} has no pending approval on record`);
    }
    if (!pr.supplier_ID) {
      return req.error(400, `Requisition ${pr.requisitionNumber} has no supplier assigned — cannot generate a Purchase Order`);
    }

    await UPDATE(Approvals, approval.ID).with({
      status: 'APPROVED',
      comment,
      decidedAt: new Date().toISOString(),
      decidedBy: req.user.id,
    });

    const items = await SELECT.from(PurchaseRequisitionItems).where({ requisition_ID: id });
    const poId = cds.utils.uuid();
    const poNumber = await nextNumber(PurchaseOrders, 'PO');

    await INSERT.into(PurchaseOrders).entries({
      ID: poId,
      poNumber,
      supplier_ID: pr.supplier_ID,
      sourceRequisition_ID: id,
      status: 'DRAFT',
      currency: pr.currency,
      totalAmount: pr.totalAmount,
    });

    await INSERT.into(PurchaseOrderItems).entries(
      items.map((item) => ({
        ID: cds.utils.uuid(),
        purchaseOrder_ID: poId,
        material: item.material,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        amount: item.amount,
      }))
    );

    await UPDATE(PurchaseRequisitions, id).with({ status: 'CONVERTED', purchaseOrder_ID: poId });

    return SELECT.one.from(PurchaseRequisitions, id);
  });

  // -- rejectRequisition: SUBMITTED -> REJECTED ----------------------------
  // Named rejectRequisition (not `reject`) because `reject` collides with
  // a method CAP's ApplicationService base class already defines — CAP
  // warns and silently refuses to bind the custom handler if you use it.

  this.on('rejectRequisition', PurchaseRequisitions, async (req) => {
    const id = req.params[0].ID ?? req.params[0];
    const { comment } = req.data;

    if (!comment) {
      return req.error(400, 'A comment is required to reject a requisition');
    }

    const pr = await SELECT.one.from(PurchaseRequisitions, id);
    if (!pr) return req.error(404, `Requisition ${id} not found`);
    if (pr.status !== 'SUBMITTED') {
      return req.error(400, `Requisition ${pr.requisitionNumber} is ${pr.status} — only a SUBMITTED requisition can be rejected`);
    }

    const approval = await SELECT.one.from(Approvals).where({ requisition_ID: id, status: 'PENDING' });
    if (approval) {
      await UPDATE(Approvals, approval.ID).with({
        status: 'REJECTED',
        comment,
        decidedAt: new Date().toISOString(),
        decidedBy: req.user.id,
      });
    }

    await UPDATE(PurchaseRequisitions, id).with({ status: 'REJECTED' });

    return SELECT.one.from(PurchaseRequisitions, id);
  });
});
