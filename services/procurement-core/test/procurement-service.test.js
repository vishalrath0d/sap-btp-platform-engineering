'use strict';

const cds = require('@sap/cds');
const path = require('path');

// cds.test spins up the service in-process against an isolated in-memory
// sqlite db (see package.json's cds.requires.[test].db) and returns axios-
// backed request helpers already carrying the right base URL.
const { GET, POST, expect } = cds.test(path.join(__dirname, '..'));

const alice = { auth: { username: 'alice', password: '' } }; // Requester
const bob = { auth: { username: 'bob', password: '' } }; // Approver
const carol = { auth: { username: 'carol', password: '' } }; // both roles

const PR = (id) => `/procurement/PurchaseRequisitions(${id})`;

describe('ProcurementService', () => {
  test('seed data loaded with the three lifecycle states', async () => {
    const { data } = await GET('/procurement/PurchaseRequisitions?$orderby=requisitionNumber', alice);
    expect(data.value).to.have.length(3);
    // requisitionNumber order is PR-00001 (CONVERTED), PR-00002 (SUBMITTED), PR-00003 (DRAFT)
    expect(data.value.map((r) => r.status)).to.deep.equal(['CONVERTED', 'SUBMITTED', 'DRAFT']);
  });

  test('submit computes totalAmount from items and opens a PENDING approval at the right tier', async () => {
    const { data: draft } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'DRAFT'",
      alice
    );
    const id = draft.value[0].ID;

    const { data: submitted } = await POST(`${PR(id)}/ProcurementService.submit`, {}, alice);
    expect(submitted.status).to.equal('SUBMITTED');
    expect(submitted.totalAmount).to.equal(12600); // 40*210 + 120*35, see seed data

    const { data: approvals } = await GET(
      `/procurement/Approvals?$filter=requisition_ID eq ${id}`,
      alice
    );
    expect(approvals.value).to.have.length(1);
    expect(approvals.value[0].status).to.equal('PENDING');
    expect(approvals.value[0].approverRole).to.equal('DIRECTOR'); // 12600 is between 10k and 50k
  });

  test('submit rejects a requisition that already has items but is not DRAFT', async () => {
    // PR-00001 is CONVERTED in the seed data
    const { data: converted } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'CONVERTED'",
      alice
    );
    const id = converted.value[0].ID;

    await expect(POST(`${PR(id)}/ProcurementService.submit`, {}, alice)).to.be.rejectedWith(/DRAFT/);
  });

  test('approve requires the Approver role, not just any authenticated user', async () => {
    const { data: submitted } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'SUBMITTED'",
      alice
    );
    const id = submitted.value[0].ID;

    await expect(
      POST(`${PR(id)}/ProcurementService.approve`, { comment: 'trying anyway' }, alice)
    ).to.be.rejectedWith(/403/);
  });

  test('approve converts the requisition and generates a matching Purchase Order', async () => {
    const { data: submittedList } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'SUBMITTED'",
      alice
    );
    const pr = submittedList.value[0];

    const { data: approved } = await POST(
      `${PR(pr.ID)}/ProcurementService.approve`,
      { comment: 'Approved within budget' },
      bob
    );
    expect(approved.status).to.equal('CONVERTED');
    expect(approved.purchaseOrder_ID).to.not.equal(null);

    const { data: po } = await GET(`/procurement/PurchaseOrders(${approved.purchaseOrder_ID})`, alice);
    expect(po.status).to.equal('DRAFT');
    expect(po.totalAmount).to.equal(approved.totalAmount);
    expect(po.supplier_ID).to.equal(pr.supplier_ID);

    const { data: items } = await GET(
      `/procurement/PurchaseOrderItems?$filter=purchaseOrder_ID eq ${approved.purchaseOrder_ID}`,
      alice
    );
    const itemTotal = items.value.reduce((sum, i) => sum + i.amount, 0);
    expect(itemTotal).to.equal(po.totalAmount);
  });

  test('approve is blocked once the requisition is no longer SUBMITTED', async () => {
    const { data: converted } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'CONVERTED'",
      alice
    );
    const id = converted.value[0].ID;

    await expect(
      POST(`${PR(id)}/ProcurementService.approve`, { comment: 'double approve' }, bob)
    ).to.be.rejectedWith(/400/);
  });

  test('rejectRequisition requires a comment', async () => {
    const { data: submitted } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'SUBMITTED'",
      alice
    );
    const id = submitted.value[0].ID;

    await expect(
      POST(`${PR(id)}/ProcurementService.rejectRequisition`, {}, bob)
    ).to.be.rejectedWith(/comment is required/);
  });

  test('rejectRequisition moves a SUBMITTED requisition to REJECTED and closes its approval', async () => {
    const { data: submitted } = await GET(
      "/procurement/PurchaseRequisitions?$filter=status eq 'SUBMITTED'",
      alice
    );
    const id = submitted.value[0].ID;

    const { data: rejected } = await POST(
      `${PR(id)}/ProcurementService.rejectRequisition`,
      { comment: 'Over budget for this quarter' },
      bob
    );
    expect(rejected.status).to.equal('REJECTED');

    const { data: approvals } = await GET(`/procurement/Approvals?$filter=requisition_ID eq ${id}`, alice);
    expect(approvals.value[0].status).to.equal('REJECTED');
  });

  test('a user with both roles (carol) can both submit and approve their own requisition', async () => {
    const { data: created } = await POST(
      '/procurement/PurchaseRequisitions',
      {
        description: 'Test item for dual-role user',
        requestedBy: 'carol@procureiq.example',
        department: 'QA',
        supplier_ID: '10000000-0000-0000-0000-000000000001',
        items: [{ material: 'Test widget', quantity: 10, unitPrice: 5 }],
      },
      carol
    );
    expect(created.status).to.equal('DRAFT');

    const { data: submitted } = await POST(`${PR(created.ID)}/ProcurementService.submit`, {}, carol);
    expect(submitted.totalAmount).to.equal(50);

    const { data: approved } = await POST(
      `${PR(created.ID)}/ProcurementService.approve`,
      { comment: 'self-approved for test' },
      carol
    );
    expect(approved.status).to.equal('CONVERTED');
  });
});
