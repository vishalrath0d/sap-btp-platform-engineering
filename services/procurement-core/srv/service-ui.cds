using ProcurementService as service from './service';

/**
 * SAP Fiori Elements annotations, kept in their own file rather than mixed
 * into service.cds — the standard CAP convention once a project has real UI
 * annotations, so the API contract (service.cds) and its presentation layer
 * (this file) can be read and changed independently.
 *
 * This is what actually generates the List Report + Object Page UI at
 * /$fiori-preview during local dev — zero hand-written HTML/JS. A real
 * deployable Fiori Elements app (its own webapp/ + manifest.json, ready for
 * html5-repo deployment on BTP) is the natural next step once we're
 * deploying for real; that needs the Fiori Elements Yeoman generator or
 * SAP's Fiori tools VS Code extension, neither of which run headlessly, so
 * it's scoped as a follow-up rather than forced through here. Everything
 * these annotations describe carries over unchanged to that generated app.
 */

annotate service.PurchaseRequisitions with @(
  UI: {
    HeaderInfo: {
      TypeName: 'Purchase Requisition',
      TypeNamePlural: 'Purchase Requisitions',
      Title: { Value: requisitionNumber },
      Description: { Value: description },
    },
    SelectionFields: [status, department, supplier_ID],
    LineItem: [
      { Value: requisitionNumber, Label: 'Number' },
      { Value: description, Label: 'Description' },
      { Value: status, Label: 'Status', Criticality: statusCriticality },
      { Value: department, Label: 'Department' },
      { Value: totalAmount, Label: 'Total' },
      { Value: currency, Label: 'Currency' },
      { Value: requestedBy, Label: 'Requested By' },
    ],
    Facets: [
      { $Type: 'UI.ReferenceFacet', Label: 'Requisition', Target: '@UI.FieldGroup#Main' },
      { $Type: 'UI.ReferenceFacet', Label: 'Line Items', Target: 'items/@UI.LineItem' },
      { $Type: 'UI.ReferenceFacet', Label: 'Approvals', Target: 'approvals/@UI.LineItem' },
    ],
    FieldGroup#Main: {
      Data: [
        { Value: requisitionNumber },
        { Value: description },
        { Value: status },
        { Value: department },
        { Value: requestedBy },
        { Value: supplier_ID, Label: 'Supplier' },
        { Value: totalAmount },
        { Value: currency },
      ],
    },
  },
) {
  status @Common.Text: statusText;
};

// A virtual-ish pair of computed fields for status coloring/readability in
// the list — kept simple (string mapping in service.js) rather than a full
// value-help/text-association model, which would be overkill here.
// UI.Criticality values: 1=Negative(red) 2=Critical(orange) 3=Positive(green) 5=Neutral(grey)
// `=` (a CDS *calculated element*, not the `as`-aliased form this used
// to be) is the real fix for a genuine bug hit live on the deployed
// HANA instance: with the old `... as statusCriticality : Integer`
// form, HANA's generated INSERT for PurchaseRequisitions ended up
// listing `status` twice ("duplicate column name: STATUS") - the
// compiler resolved the `status as statusText` alias back to the
// source column name `status` when building the writable column set
// for the base table, colliding with the real `status` column already
// in that same INSERT. SQLite (local dev, this service's own test
// suite) never exercises this codepath, which is why it wasn't caught
// before deploying.
//
// `virtual` was tried first and is the WRONG fix, worth recording:
// it does stop the column from ever appearing in INSERT/UPDATE, but it
// also strips it from READS entirely (confirmed live - a real GET
// stopped returning statusCriticality/statusText at all once marked
// virtual), because `virtual` means "no database backing whatsoever,
// populate via handler code only" - it discards the case/when
// definition, not just its writability. A CDS *calculated element*
// (this `=` syntax) is the construct that actually matches what these
// fields are: computed by a real SQL expression in the generated VIEW
// (so reads/the Fiori UI's Criticality coloring and status label still
// work), while being excluded from INSERT/UPDATE automatically because
// calculated elements are derived, not stored - confirmed against the
// real generated HANA artifacts (`cds build`): the base
// sap.procureiq.PurchaseRequisitions.hdbtable has neither column, while
// ProcurementService.PurchaseRequisitions.hdbview computes both via the
// same case/when SQL this project always intended.
extend projection service.PurchaseRequisitions with {
  case status
    when 'DRAFT' then 5
    when 'SUBMITTED' then 2
    when 'APPROVED' then 2
    when 'CONVERTED' then 3
    when 'REJECTED' then 1
    else 0
  end as statusCriticality : Integer,
  case status
    when 'DRAFT' then 'DRAFT'
    when 'SUBMITTED' then 'SUBMITTED'
    when 'APPROVED' then 'APPROVED'
    when 'CONVERTED' then 'CONVERTED'
    when 'REJECTED' then 'REJECTED'
    else status
  end as statusText : String,
};

annotate service.PurchaseRequisitionItems with @(
  UI.LineItem: [
    { Value: material, Label: 'Material' },
    { Value: quantity, Label: 'Qty' },
    { Value: unitPrice, Label: 'Unit Price' },
    { Value: amount, Label: 'Amount' },
  ]
);

annotate service.Approvals with @(
  UI.LineItem: [
    { Value: approverRole, Label: 'Approver Role' },
    { Value: status, Label: 'Status' },
    { Value: decidedBy, Label: 'Decided By' },
    { Value: decidedAt, Label: 'Decided At' },
    { Value: comment, Label: 'Comment' },
  ]
);

annotate service.Suppliers with @(
  UI: {
    HeaderInfo: { TypeName: 'Supplier', TypeNamePlural: 'Suppliers', Title: { Value: name } },
    SelectionFields: [status, riskRating, country],
    LineItem: [
      { Value: name, Label: 'Name' },
      { Value: country, Label: 'Country' },
      { Value: riskRating, Label: 'Risk Rating' },
      { Value: status, Label: 'Status' },
    ],
  }
);
