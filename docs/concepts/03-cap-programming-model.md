# CAP: the SAP Cloud Application Programming Model

Written after building `services/procurement-core` — every claim here is
checked against that actual, running, tested code, not against tutorial memory.

## What CAP is, in one paragraph

CAP is SAP's opinionated framework for building business services: you declare
a **domain model** and a **service** in CDS (Core Data & Services — SAP's own
DSL), and CAP generates the OData/REST API, the database schema, and a large
amount of boilerplate (CRUD handlers, pagination, `$filter`/`$expand`/`$select`
support, draft handling, multitenancy hooks) for free. You write **custom
code only for the business logic that isn't generic CRUD** — in our case, the
requisition→approval→PO workflow.

## The two CDS files and what each is for

| File | Role |
|---|---|
| `db/schema.cds` | The **persistence model** — entities, fields, associations/compositions. This is what gets deployed to SQLite locally and HANA in the cloud. |
| `srv/service.cds` | The **API surface** — which entities are exposed, under what path, as what shape (projections can rename/hide/restrict fields), plus custom actions/functions. |

`procurement-core`'s split: `db/schema.cds` defines six entities
(`Suppliers`, `PurchaseRequisitions`, `PurchaseRequisitionItems`, `Approvals`,
`PurchaseOrders`, `PurchaseOrderItems`); `srv/service.cds` exposes them under
`ProcurementService` at `/procurement`, with `Suppliers`/`PurchaseOrders`/
`PurchaseOrderItems`/`Approvals` marked `@readonly` — the API only allows
writes where the domain actually allows them (you create/edit requisitions;
everything else is a side effect of the workflow).

## Association vs. Composition — this is not a stylistic choice

```cds
entity PurchaseRequisitions : cuid, managed {
  supplier : Association to Suppliers;               // reference to something
  items    : Composition of many PurchaseRequisitionItems  // ownership
               on items.requisition = $self;
}
```

- **Association** = a reference. A `PurchaseRequisition` *points at* a
  `Supplier`; deleting the requisition has no effect on the supplier.
- **Composition** = ownership. `PurchaseRequisitionItems` only exist *through*
  their parent requisition — CAP's deep-insert/deep-delete semantics follow
  this (deleting a requisition cascades to its items; a bare `POST` to
  `PurchaseRequisitions` with a nested `items` array creates both in one
  transaction — this is exactly what the "carol" test in
  `test/procurement-service.test.js` relies on).

Getting this backwards is a common CAP mistake: modeling ownership as an
Association means you lose cascade behavior and deep-insert for free; modeling
a plain reference as a Composition means deleting the "owner" would silently
delete something it doesn't actually own.

## `cuid` and `managed` — reuse before you reinvent

```cds
using { cuid, managed } from '@sap/cds/common';

entity Suppliers : cuid, managed { ... }
```

`cuid` adds a UUID `key ID`. `managed` adds `createdAt`/`createdBy`/
`modifiedAt`/`modifiedBy`, auto-populated by CAP on every write (visible in the
API responses in `services/procurement-core/README.md`'s example — every
requisition and PO in this service carries a real audit trail with zero
custom code for it). Both come from CAP's own `@sap/cds/common` — writing
these by hand is a sign you're fighting the framework, not using it.

## Actions: where the actual business logic lives

Generic CRUD is auto-generated. The workflow is not — it's three custom
actions on `PurchaseRequisitions`:

```cds
entity PurchaseRequisitions as projection on db.PurchaseRequisitions actions {
  @requires: 'Requester'
  action submit()                            returns PurchaseRequisitions;

  @requires: 'Approver'
  action approve(comment: String)            returns PurchaseRequisitions;

  @requires: 'Approver'
  action rejectRequisition(comment: String)  returns PurchaseRequisitions;
};
```

`@requires` is CAP's declarative RBAC — enforced by the framework *before*
your handler code even runs. Verified directly: `alice` (Requester-only)
calling `approve` gets a `403` without a single `if` statement in
`srv/service.js` — see the "approve requires the Approver role" test.

Implementation is `this.on('submit', PurchaseRequisitions, async (req) => {...})`
in `srv/service.js` — the `on` handler *replaces* the (non-existent, for a
custom action) generic behavior entirely, versus `before`/`after` handlers
(used here for auto-numbering and computed `amount` fields) which wrap around
generic CRUD without replacing it.

## Two mistakes made while building this, worth knowing in advance

1. **A custom action named `reject` silently fails to bind.** CAP's
   `ApplicationService` base class already has a method called `reject` (used
   internally for OData batch/draft handling). Defining your own `action
   reject(...)` doesn't error at compile time — it logs a warning and the
   custom handler is never wired, so calling it returns `501 no handler`. The
   fix was renaming to `rejectRequisition`. **Lesson: avoid action names that
   read like they could be framework-reserved words** (`reject`, `draft`,
   `save`, `edit` are all worth double-checking).
2. **The `.js` implementation file must share the exact basename of its `.cds`
   file**, not the service name. `srv/service.cds` defines `ProcurementService`,
   but the implementation had to be named `srv/service.js` — a file named
   `srv/procurement-service.js` was silently never loaded (every action
   returned `501`, same symptom as mistake #1, different cause). Confirmed via
   `cds-serve`'s startup log, which prints `impl: 'srv/service.js'` only once
   the naming is correct — that log line is the fast way to check this instead
   of guessing.

## Mocked auth for local dev

```json
"cds": {
  "requires": {
    "auth": {
      "kind": "mocked",
      "users": {
        "alice": { "roles": ["Requester"] },
        "bob":   { "roles": ["Approver"] }
      }
    }
  }
}
```

This is what makes `@requires: 'Approver'` testable and demoable *without* a
BTP account, XSUAA, or any real identity provider — CAP substitutes a fake
identity layer that still enforces the same `@requires` annotations the real
XSUAA-backed deployment will. Basic-auth against these fake users (`curl -u
alice:`) is enough to exercise real RBAC locally. Swapping `kind: "mocked"`
for `kind: "xsuaa"` later, with a matching `xs-security.json` role/scope
mapping, is the only change needed to go from this to a real BTP deployment —
the `@requires` annotations in `service.cds` don't change at all.
