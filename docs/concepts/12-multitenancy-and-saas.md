# Multitenancy and SaaS (MTX)

Documented, not built — see "Known limitations" below for exactly why,
and what would need to be true before building it for real is worth
doing rather than half-simulating something that needs real
infrastructure to mean anything.

## Does it actually work in a real (prod) BTP landscape? Yes — unambiguously

Worth stating plainly, since "documented, not built" could be misread as
doubt about the technology itself: **`@sap/cds-mtxs` is SAP's own
standard, fully-supported, widely-used-in-production architecture** for
exactly this — it's how real SAP partners and ISVs run one SaaS
application across many customer subaccounts today, not an experimental
or shaky feature. Nothing about it is unproven or prod-risky.

The reason this project hasn't built it isn't "will it work" — it's
**"can this project verify it works, from where this project currently
stands"**. That answer is genuinely no *right now*: proving multitenancy
actually works means having a second real subaccount subscribe to the
app and confirming tenant isolation for real (see step 4 below) — there
is no trial-account or local equivalent of "a second subaccount
subscribes," the same way there's no local equivalent of a second BTP
region. Once this project has a real landscape with more than one
subaccount to test against, building and verifying MTX for real is
straightforward, expected work — not a research problem, not something
requiring new technology to be invented. The gap is infrastructure
availability, not capability.

## What CAP multitenancy actually is

`@sap/cds-mtxs` — the CAP toolkit for turning a single-tenant app like
`procurement-core` into a SaaS application serving many isolated tenant
subaccounts from one codebase and one deployment. Not a config flag; a
real architectural shift with specific moving parts:

- **`saas-registry`** and **`service-manager`** — two additional MTA
  resources a multitenant CAP app requires, beyond what `procurement-core`
  currently has. `saas-registry` is what makes the app subscribable from
  another subaccount's BTP cockpit at all; `service-manager` is what lets
  the app provision tenant-specific service instances (an HDI container
  per tenant) programmatically.
- **The `zid` JWT claim** — XSUAA tokens for a multitenant app carry a
  `zid` (identity zone ID) claim identifying which tenant the request
  belongs to. CAP's multitenancy layer uses this to route each request to
  the right tenant's data — the mechanism that actually enforces tenant
  isolation, not just a `WHERE tenant_id = ?` convention a developer has
  to remember everywhere.
- **Subscription-time, not deploy-time, provisioning** — a new tenant's
  HDI container is provisioned when that tenant *subscribes* to the app
  (a SaaS Provisioning service callback into the app's own subscription
  endpoint), not when the app itself is deployed. This is the part that
  most needs a real BTP landscape to mean anything: there's no local
  equivalent of "a new subaccount subscribes to this app."

## Why `procurement-core` would be a legitimate MTX candidate

Multiple companies each running their own isolated ProcureIQ instance,
from one deployed codebase, is a completely plausible real scenario for
this exact domain — this isn't a contrived example bolted on to check a
box.

## Known limitations (honesty notes) — why this is documented, not built

Real CAP multitenancy needs a SaaS Provisioning service instance (BTP-only,
no local equivalent) to exercise the actual subscription flow, and in
practice a genuinely multi-tenant HDI-container-per-tenant setup needs
HANA, not SQLite, to demonstrate meaningfully — `procurement-core`'s local
dev loop is SQLite specifically to stay fast and dependency-free (see
`03-cap-programming-model.md`). Half-wiring `@sap/cds-mtxs` locally
without either of those would produce code that *looks* multitenant but
has never actually onboarded a second tenant — worse than not building it
at all, since it would misrepresent verification the project hasn't done.
This is the same judgment call already made for `services/integration-flow`
and `supplier-master-abap`: documented accurately, built once the
account/infrastructure exists to verify it for real, not before.

## What actually building this later would look like

1. Add `saas-registry` and `service-manager` MTA resources to `mta.yaml`.
2. Add the CAP-side subscription/unsubscription handlers (`@sap/cds-mtxs`
   provides these largely out of the box).
3. Deploy to a real subaccount; create a second subaccount; have it
   subscribe.
4. Verify tenant isolation for real: data created under tenant A must be
   invisible to tenant B, checked via two real subscribed subaccounts, not
   asserted.

Step 4 is the actual bar this project holds itself to elsewhere (see
`syncLegacySuppliers`'s idempotency being *proven*, not just implemented)
— worth restating as the target for when this gets built, not lowering
the bar just because it needs the account.
