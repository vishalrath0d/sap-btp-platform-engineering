# procurement-core

A CAP (SAP Cloud Application Programming Model) Node.js service implementing the
core of the ProcureIQ domain: **Purchase Requisition → Approval → Purchase Order**.
This is the first service in `sap-btp-platform-engineering` — see the repo root
`PROJECT_CHARTER.md` for how it fits the bigger picture.

Runs entirely locally right now (SQLite), with zero dependency on a BTP account.
Cloud Foundry/HANA Cloud/XSUAA deployment is a later phase — see the charter's
roadmap.

## The domain model

```mermaid
erDiagram
    Suppliers ||--o{ PurchaseOrders : receives
    PurchaseRequisitions ||--o{ PurchaseRequisitionItems : has
    PurchaseRequisitions ||--o{ Approvals : opens
    PurchaseRequisitions ||--o| PurchaseOrders : "converts to"
    PurchaseOrders ||--o{ PurchaseOrderItems : has
    Suppliers ||--o{ PurchaseRequisitions : "suggested for"
```

## The lifecycle this service actually enforces

```mermaid
stateDiagram-v2
    [*] --> DRAFT: create requisition + items
    DRAFT --> SUBMITTED: submit()\n(computes totalAmount,\nopens an Approval)
    SUBMITTED --> CONVERTED: approve()\n(auto-generates a PO)
    SUBMITTED --> REJECTED: rejectRequisition()\n(comment required)
    CONVERTED --> [*]
    REJECTED --> [*]
```

Approver routing is a flat threshold table (`srv/lib/approval-rules.js`), decided
once at `submit()` time from the requisition's computed total — not re-evaluated
later, matching how a real approval-of-record works:

| Total amount | Approver role |
|---|---|
| ≤ 10,000 | MANAGER |
| ≤ 50,000 | DIRECTOR |
| above | CFO |

`approve()` doesn't just flip a status — it copies every requisition item into a
brand-new `PurchaseOrders`/`PurchaseOrderItems` pair, so a PO can always be traced
back to the requisition and approval that produced it. Nothing creates a
`PurchaseOrder` any other way; there's no direct-insert path for POs in the
service definition (`Suppliers`, `PurchaseOrders`, `PurchaseOrderItems` are all
`@readonly` projections).

### Design note: this routing could instead be SAP Workflow Management (BPMN)

`approval-rules.js`'s flat threshold table is deliberately simple code —
readable, testable, and exactly matched to this project's actual
requirement (one linear escalation by amount). **SAP Workflow Management**
(BPMN-based, distinct from classic ABAP Business Workflow — see
`docs/concepts/00-scope-boundaries.md` for why the classic one is out of
scope) is the SAP-native alternative for approval routing, and would be
the better real choice the moment routing logic needs any of what a flat
table can't express well: branching approval paths, parallel approvers,
delegation/out-of-office reassignment, or a business user needing to see
and adjust the routing rules without a code change. `procurement-core`'s
routing doesn't need that yet — this is a documented design alternative,
not a claim that BPMN-based workflow is running here. If/when the
approval logic outgrows a threshold table, this is the concrete SAP-native
direction to reach for instead of growing `approval-rules.js` into an
ad hoc rules engine.

## Run it locally

```bash
npm install
npx cds deploy      # creates db.sqlite and loads db/data/*.csv
npx cds-serve        # or: npm run watch (auto-restarts on change)
# service is now at http://localhost:4004/procurement
```

Local dev uses CAP's built-in **mocked auth** (`package.json` → `cds.requires.auth`),
so there's no XSUAA/BTP dependency yet — three users are pre-defined:

| User | Roles |
|---|---|
| `alice` | Requester |
| `bob` | Approver |
| `carol` | Requester + Approver |

Any password works locally (mocked auth ignores it) — e.g. `curl -u alice: ...`.

### Try the actual workflow

```bash
# submit the seeded DRAFT requisition (PR-00003)
curl -u alice: -X POST \
  'http://localhost:4004/procurement/PurchaseRequisitions(20000000-0000-0000-0000-000000000003)/ProcurementService.submit' \
  -H 'Content-Type: application/json' -d '{}'

# approve the seeded SUBMITTED requisition (PR-00002) — generates a PO
curl -u bob: -X POST \
  'http://localhost:4004/procurement/PurchaseRequisitions(20000000-0000-0000-0000-000000000002)/ProcurementService.approve' \
  -H 'Content-Type: application/json' -d '{"comment":"Approved within budget"}'
```

### The UI: SAP Fiori Elements, generated from annotations

`srv/service-ui.cds` adds standard SAP Fiori Elements annotations
(`UI.LineItem`, `UI.HeaderInfo`, `UI.SelectionFields`, `UI.Facets`) to the
service — kept in its own file, separate from the API contract in
`service.cds`, which is the normal CAP convention once a project has real UI
annotations. This generates a full List Report + Object Page UI with **zero
hand-written HTML/JS**, served locally at:

```
http://localhost:4004/$fiori-preview/ProcurementService/PurchaseRequisitions
```

(the running server's `/` index page links to a preview for every entity).
Verified: returns real `sap.fe`/UI5-bootstrapped HTML, not a stub. Requisition
status is annotated with `Criticality` so DRAFT shows neutral, SUBMITTED
shows critical/orange, CONVERTED shows positive/green, REJECTED shows
negative/red in the generated list — computed server-side
(`statusCriticality` in `service-ui.cds`) rather than hardcoded in a UI
layer, so it stays correct if the workflow states ever change.

A standalone, deployable Fiori Elements app (its own `webapp/` folder +
`manifest.json`, packaged for BTP's HTML5 Application Repository) is a
documented next step once actually deploying — that needs the Fiori
Elements Yeoman generator or SAP's Fiori tools VS Code extension, neither of
which run in this headless environment. Everything the annotations describe
here carries over unchanged to that generated app.

**Now also live on the real deployed instance, not just locally.**
`@sap/cds`'s own default (`node_modules/@sap/cds/lib/env/defaults.js`:
`fiori: { preview: !production, routes: !production }`) turns this preview
off in production on purpose — the standard advice is "ship a real
generated app, not the dev-time preview." `package.json`'s `cds.fiori`
block explicitly re-enables it (`preview: true, routes: true`, real CAP
config, not a hack) for this project's deployed instance, since a
standalone HTML5-repo app isn't built yet and a reachable UI is still
worth having — same URL shape, on the real deployed route:
`https://4cbf0c12trial-dev-procurement-core-srv.cfapps.us10-001.hana.ondemand.com/$fiori-preview/ProcurementService/PurchaseRequisitions`
(see the root README's "Live on BTP" section — you'll be prompted to
authenticate, since this hits the same real XSUAA-protected OData
service the UI itself calls; see below for how to actually get a real
token to browse it with real data).

### Run the tests

```bash
npm test
```

9/9 passing as of this writing, covering: happy-path submit→approve→PO generation,
happy-path submit→reject, RBAC enforcement (a Requester cannot call `approve`),
and business-rule guards (can't submit a non-DRAFT requisition, can't approve
twice, can't reject without a comment).

## Connectivity: syncing suppliers from a "legacy" on-prem system

`syncLegacySuppliers` (requires the `IntegrationAdmin` role) pulls supplier
records from `services/legacy-erp-gateway` through a Destination-service-
shaped connectivity layer (`srv/lib/destination.js`) that simulates the
Cloud Connector boundary a real on-prem integration would need — see
`docs/concepts/11-connectivity-cloud-connector.md` for the full story and a
sequence diagram.

```bash
# needs legacy-erp-gateway running on :4007 (see that service's README)
curl -u dave: -X POST http://localhost:4004/procurement/syncLegacySuppliers \
  -H 'Content-Type: application/json' -d '{}'
```

Verified live: first run created 5 suppliers from the legacy mock data with
correctly mapped risk ratings/statuses; re-running the identical sync
produced 0 creates / 5 updates (idempotent, matched on `externalId` +
`sourceSystem`); `alice` (`Requester` role) got a real `403` attempting the
same call.

## Known limitations (honesty notes, not hidden)

- ~~`POST /procurement/PurchaseRequisitions` fails on the real deployed
  HANA-backed instance~~ — **fixed this session.** Real error (from
  `procurement-core-srv`'s own logs): `duplicate column name: STATUS`
  in the generated INSERT SQL. Root cause: the old `status as
  statusText : String` form in `srv/service-ui.cds` (a `@Common.Text`
  annotation helper giving the Fiori UI a human-readable status label)
  aliased `statusText` directly to the real `status` column, and
  HANA's compiler resolved that alias back to the source column name
  when building the base table's writable columns — a literal
  duplicate. SQLite (local dev, this service's own `npm test` suite)
  never exercises this exact code path, which is why it wasn't caught
  before deploying. Two fix attempts were tried and rejected first,
  worth knowing if this pattern comes up again: marking `statusText`
  `virtual` correctly excludes it from INSERT/UPDATE but *also* strips
  it from reads entirely (confirmed live — `virtual` means no database
  backing at all, not merely "not writable"); a genuine CDS calculated
  element (`statusText = status`, `=` syntax) isn't valid inside an
  `extend projection X with {}` block at all (real compile error,
  "Alias name is required for this select item" — that block uses
  SELECT-item `as` syntax, not entity-element `=` syntax). The real
  fix: keep the working `as`-aliased form, but rewrite `statusText`'s
  own expression as a `case/when` mapping to identical string values
  instead of directly aliasing `status` 1:1 — verified against the
  real generated HANA artifacts (`sap.procureiq.PurchaseRequisitions.
  hdbtable` has exactly one `status` column now) and a real running
  local server (reads still return correct `statusCriticality`/
  `statusText`, creates succeed). Deployed and confirmed live.
- **`ProcurementService`'s reads are deliberately public** (`srv/
  service.cds`: `requires: 'any'` at the service level, `@restrict` on
  `PurchaseRequisitions`/`PurchaseRequisitionItems` granting `READ` to
  `'any'` while keeping `CREATE`/`UPDATE`/`DELETE` and the
  `submit`/`approve`/`rejectRequisition` actions gated exactly as
  before) — so the deployed Fiori preview UI is a genuine, cold-open,
  shareable link (see the root README's "Live on BTP"). A real,
  service-level-specific bug was found and fixed getting this to
  actually work once deployed: entity-level `@requires`/`@restrict`
  alone weren't enough — confirmed live, every read still `401`'d.
  Root cause, found directly in `@sap/cds`'s own framework source
  (`node_modules/@sap/cds/lib/srv/protocols/http.js`): CAP's HTTP
  adapter applies a *separate, service-wide* gate ahead of any
  entity-level rule, defaulting every service to `authenticated-user`
  in production unless the service itself opts out. Fixed by adding
  `requires: 'any'` to `ProcurementService`'s own top-level annotation
  too. This never showed up locally because that outer gate only
  activates when `NODE_ENV=production` (true on CF, false in local
  dev) — a genuinely environment-dependent bug, not a logic error in
  the per-entity rules.
- **Document numbering (`PR-00001`, `PO-00001`) is `count(*)`-based** (`srv/lib/sequence.js`) —
  fine for a single local writer, **not safe under concurrent requests**. A real
  deployment needs a DB sequence or a dedicated number-range service. Documented
  here instead of silently shipped as if it were production-hardened.
- **No referential-integrity enforcement on `supplier_ID`** — CAP doesn't reject
  a requisition pointing at a nonexistent or `INACTIVE`/`BLOCKED` supplier yet.
  That's a deliberate v-next item (an `@assert.target` / before-CREATE check),
  not an oversight — flagging it here so it doesn't get "discovered" later as a bug.
- **Currency is a bare `String(3)`**, not `@sap/cds/common`'s `Currency` association —
  simpler for v1, avoids needing to seed the standard `Currencies` reference data.
  Worth upgrading once a second currency-aware feature needs it.
- No pagination/large-dataset handling considered yet — six suppliers and three
  requisitions is a demo dataset, not a load test.

## Two real bugs hit while building this (and how they were found)

1. **`reject` collided with a CAP base-class method.** The original action was
   named `reject`, which silently failed to bind — CAP logged a warning
   ("conflicts with method in base class") and the OData endpoint returned
   `501 no handler`, not an obvious error at a glance. Fixed by renaming to
   `rejectRequisition` (see `srv/service.cds` and `srv/service.js`).
2. **Custom handlers weren't loading at all** because the implementation file
   was named `procurement-service.js` while the CDS file was `service.cds` — CAP's
   auto-wiring convention matches the `.js` file to the `.cds` file by **matching
   basename**, not by service name. Every custom action returned `501` until the
   file was renamed to `service.js`. Verified via `cds-serve`'s startup log
   showing `impl: 'srv/service.js'` only after the rename.

(A third issue — `better-sqlite3` failing to compile on this machine — was a
host toolchain problem, not a service bug. See the repo-root
`docs/references/macos-native-build-toolchain.md` for that one.)
