# supplier-master-abap — ABAP Cloud / RAP

The system-of-record for supplier master data, as it would actually exist
in a real landscape: an **ABAP Cloud (Steampunk)** business object on the
**BTP ABAP Environment**, built with **RAP (RESTful ABAP Programming
Model)**, git-versioned via **gCTS**. `procurement-core`'s own `Suppliers`
entity currently owns this data directly (SQLite locally, HANA Cloud once
deployed) — a real side-by-side extension would instead **project** or
**replicate** supplier master data out of a system like this one, not own
it independently. This folder is that missing piece of the picture,
written as real ABAP Cloud source, same honesty level
`services/integration-flow` documents for the same class of constraint.

## Why this is source code, not just a design doc

Every file here is real, syntactically-real ABAP Cloud/RAP source —
checked against SAP's own current RAP documentation and reference
patterns (`abap-cheat-sheets`, `EntityBehaviorDefinition` keyword docs),
not invented. What it genuinely can't be, in this environment: **compiled
or run** — there is no local ABAP Cloud runtime, and RAP development only
happens against a real BTP ABAP Environment instance through SAP
Business Application Studio (ADT). See `PROJECT_CHARTER.md`'s "ABAP
Environment and Integration Suite" section for the concrete provisioning-
then-authoring sequence this folder is the first half of.

**One deliberate exception**: the underlying database table
(`zprocureiq_supp`) is *not* included as a hand-authored DDIC XML file.
Real ABAP Cloud developers create transparent tables through ADT's guided
table wizard, not by hand-typing the DDIC metadata format — fabricating
that XML here would be a low-confidence guess with no real editing tool
to catch a mistake, unlike the CDS/behavior source below (which SAP's ADT
would syntax-check the moment it's opened). Its field list is specified
below in plain terms instead; creating it for real is the first concrete
step once a real ABAP Environment instance exists.

### `zprocureiq_supp` — fields (to be created via ADT's table wizard)

| Field | Type | Notes |
|---|---|---|
| `client` | `MANDT` | Standard client field |
| `supplier_uuid` | `RAW(16)` | Technical key (`sap.uuid.v4`) |
| `external_id` | `CHAR(20)` | The legacy system's `SUPPLIER_ID` — mirrors `procurement-core`'s `Suppliers.externalId` |
| `source_system` | `CHAR(40)` | `'LEGACY_SUPPLIER_ERP'` — mirrors `Suppliers.sourceSystem` |
| `company_name` | `CHAR(100)` | |
| `country` | `CHAR(2)` | ISO country code |
| `tax_number` | `CHAR(20)` | |
| `email` | `CHAR(100)` | |
| `risk_rating` | `CHAR(6)` | `LOW` / `MEDIUM` / `HIGH` — same enum `legacy-supplier-mapper.js`'s `RISK_MAP` produces |
| `lifecycle_status` | `CHAR(8)` | `ACTIVE` / `INACTIVE` / `BLOCKED` — same enum `STATUS_MAP` produces |
| `local_created_at` | `TIMESTAMPL` | |
| `local_created_by` | `SYCHAR12` | |
| `local_last_changed_at` | `TIMESTAMPL` | |
| `local_last_changed_by` | `SYCHAR12` | |

## Files

| File | What it is |
|---|---|
| `zi_suppliermaster.ddls.asddls` | Interface CDS view — `define root view entity` directly on `zprocureiq_supp`, `@AccessControl.authorizationCheck: #CHECK` |
| `zc_suppliermaster.ddls.asddls` | Consumption/projection CDS view — OData-exposed, adds `@ObjectModel`/`@UI` annotations |
| `zi_suppliermaster.bdef.asbdef` | Managed behavior definition — `create`, `update`, `delete`, a `validateRiskRating` validation |
| `zbp_i_suppliermaster.clas.abap` | Behavior implementation class — the validation logic, same `RISK_MAP`/`STATUS_MAP`-shaped rules `legacy-supplier-mapper.js` already enforces in the CAP/Node version |
| `zsd_suppliermaster.srvd.asdvcs` | Service definition, exposing `ZC_SupplierMaster` |

## Relationship to what already runs locally

`procurement-core`'s `Suppliers` entity and this ABAP object model the
*same* real-world data, deliberately with matching field semantics
(`externalId`/`external_id`, `sourceSystem`/`source_system`,
`riskRating`/`risk_rating` — same LOW/MEDIUM/HIGH, ACTIVE/INACTIVE/BLOCKED
enums throughout). Once both are real and deployed, the honest next step
is replication (SAP Integration Suite, or a real Destination call) from
this ABAP object *into* `procurement-core`'s own store — not building
that replication path now, since it would need both sides actually
running to test against, same reasoning `docs/concepts/12-multitenancy-
and-saas.md` gives for not half-building MTX.
