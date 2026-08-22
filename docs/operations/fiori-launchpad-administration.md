# Fiori Launchpad administration — a short, honest distinction

**Building the app** and **exposing it via Launchpad** are two different
jobs, and this project has only done the first one.

## What's actually built

`procurement-core/srv/service-ui.cds` — real SAP Fiori Elements
annotations, generating a working List Report + Object Page UI at
`/$fiori-preview/ProcurementService/PurchaseRequisitions` with zero
hand-written frontend code. This is genuinely "the app," verified running.

## What Fiori Launchpad administration actually adds on top

A **Fiori Launchpad** is the end-user entry point aggregating many apps
(this one and others) into role-based **catalogs** and **spaces/pages** —
a business user doesn't navigate to `/$fiori-preview/...` directly, they
see a curated tile in a Launchpad reflecting their assigned role
collection. Standing this up for real involves:

- Registering the app as a proper **tile** (via **SAP Build Work Zone,
  Standard Edition**, the modern Launchpad hosting service) with a
  target mapping, semantic object/action, and icon.
- **Catalogs** — grouping tiles by function/role, assigned to role
  collections (the same role collections `infra/terraform/modules/
  role-collections` provisions) — so a `Requester` sees a "raise a
  requisition" tile and an `Approver` sees an "approve requisitions"
  tile, not the same undifferentiated app view.
- **Spaces and Pages** (the modern Launchpad content model, replacing
  older Fiori Launchpad "groups") — arranging tiles into a coherent
  end-user workspace, not just a flat tile list.

None of this changes `service-ui.cds` at all — the same generated app is
what gets tiled. It's a genuinely separate, admin-facing configuration
layer on top of a developer-facing artifact, which is exactly why this
project's own scope boundary (`docs/concepts/00-scope-boundaries.md`)
treats "building the Fiori app" as squarely in scope for a BTP developer/
DevOps identity, while classic Launchpad content administration sits
closer to a Basis/administrator concern — worth a paragraph, not a
service to build.

## Known limitations

No Launchpad, catalog, space, or tile has actually been created — this
doc describes the intended distinction, not verified configuration.
