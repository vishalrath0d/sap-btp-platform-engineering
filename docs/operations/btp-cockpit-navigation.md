# Navigating the BTP cockpit for this project

Where to actually click to see everything this project provisioned and
deployed — every screen below was visited for real while building this
project, not assumed. URL shape:
`https://account.hanatrial.ondemand.com/trial/#/globalaccount/<global-account-id>/subaccount/<subaccount-id>/...`

## 1. The hierarchy — where you actually are matters

BTP's cockpit nests four levels; a resource only shows up on the screen
scoped to the level it actually lives at:

```
Global account (4cbf0c12trial)
└── Subaccount (e40cb8d7-82ad-4851-a323-12751a62402e, region us10)
    ├── Entitlements                    ← subaccount-level
    ├── Cloud Foundry
    │   └── Org (4cbf0c12trial)
    │       └── Space (dev)
    │           ├── Applications        ← space-level (the 5 deployed services)
    │           ├── Service Instances   ← space-level (HANA Cloud DB, HDI container, XSUAA)
    │           └── Service Marketplace ← space-level (what's available TO create)
    └── (Kyma environment, once approved)
```

The breadcrumb at the top of every cockpit screen
(`Trial Home / 4cbf0c12trial / trial / dev`) is the fastest way to tell
which level you're looking at — `4cbf0c12trial` there is the **org**,
not the global account (they share a name on this trial, which is
genuinely confusing the first time).

## 2. See the 5 deployed apps and their real state

**Subaccount → Cloud Foundry → Spaces → dev → Applications** (left nav:
"Applications" under the CF space). This is the single most useful
screen for this project — it lists every app, its **requested state**
(`started`/`stopped`), and its route, exactly matching `cf apps`' output.
This is also where you'd click into an app for:
- **Logs** tab — the cockpit's own tail of `cf logs <app> --recent`,
  no CLI needed.
- **Environment Variables** tab — confirms what `cf set-env` actually
  wrote (e.g. `procurement-core-srv`'s `SPEND_ANOMALY_DETECTOR_URL`,
  wired by `cf-deploy.yml`'s `wire-procurement-core-outbound-urls` job —
  see `docs/operations/networking-and-request-flow.md`).
- **Start/Stop/Restage** buttons — the UI equivalent of `cf start`/
  `cf stop`/`cf restage`. Real and relevant: BTP trial auto-stops idle
  apps (see the root README's "Live on BTP" section) — this is where
  you'd restart one by hand without needing the CLI at all.

## 3. See the service instances (HANA Cloud, HDI container, XSUAA)

**Same Space → Services → Instances.** This is exactly the screen shown
in the screenshots taken while debugging this project's real HANA/XSUAA
issues this session — each row shows **Last Operation Status**
(`Creation Failed` / `Creation Succeeded`), and clicking a row's `...` →
opens **Last Operation Details**, which surfaces the actual **Service
Broker Message** — the single most useful piece of real error text
anywhere in the cockpit (this is literally how the real "no database
available in space 'dev'" and `scaleOutLandscape is null` broker errors
that blocked `procurement-core`'s deploy were confirmed and diagnosed,
alongside `cf`'s own CLI output).

## 4. See what's provisionable (Service Marketplace)

**Same Space → Services → Service Marketplace.** Every offering/plan
your subaccount is entitled to, in this space — the cockpit's own
version of `cf marketplace`. Click any offering (e.g. `hana-cloud`) to
see its real plans and a **Create** button — this is the UI path that
does the exact same thing `cf create-service hana-cloud hana-free
procureiq-dev-hana-cloud` did for real in this project (see
`infra/terraform/README.md`'s "HANA Cloud" section for why that had to
be CLI/cf-space-scoped rather than Terraform/subaccount-scoped).

## 5. See entitlements (what the subaccount is allowed to use at all)

**Subaccount → Entitlements.** Two tabs worth knowing:
- **Entitlements** — what's currently granted, with a quota/usage bar
  per service plan. This is the screen `infra/terraform/modules/
  entitlements`' adaptive lookup mirrors (`data
  "btp_subaccount_entitlements"`) — it reads exactly this list before
  deciding what (if anything) still needs to be created.
- **Configure Entitlements → Add Service Plans** — the catalog of
  *everything available to add*, searchable by service name. This is
  where the real plan names used in this project's Terraform
  (`abap-trial/shared`, `integrationsuite-trial/trial`, etc.) were
  cross-checked against the cockpit directly, not guessed from
  documentation.

## 6. See the CF org/space itself (not an app, the space as a resource)

**Subaccount → Cloud Foundry → Org → Overview.** Shows the org's real,
SAP-assigned name (`4cbf0c12trial` — not a name this project chose, see
`infra/terraform/README.md`), its API endpoint
(`api.cf.us10-001.hana.ondemand.com` — note the `-001`, a real
regional-cell suffix distinct from the more generic `api.cf.us10...`
that looks right but silently can't see this org's resources), and
memory/route quotas. **Spaces** tab lists `dev` (the only space on this
trial) — click in for the Applications/Service Instances screens above.

## 7. Terraform's own footprint vs. what's cockpit-only

Not everything visible in the cockpit is Terraform-managed — this
project deliberately keeps some things manual/CLI-driven (see
`infra/terraform/README.md` for the full reasoning per resource):

| Cockpit screen | Managed by |
|---|---|
| Entitlements | Terraform (`modules/entitlements`, adaptive) |
| Cloud Foundry → Org | Terraform (`modules/cloudfoundry-env`, adopts the trial default) |
| Kyma environment | Terraform (`modules/kyma-env`, gated off — see `kyma_enabled`) |
| Service Instances → `procurement-core-xsuaa`, `procurement-core-db` | `cf deploy` (part of `procurement-core`'s MTA, not Terraform) |
| Service Instances → `procureiq-dev-hana-cloud` | `cf create-service` in `cf-deploy.yml` (not Terraform — see above) |
| Role Collections (Security → Role Collections) | Terraform (`modules/role-collections`, two-phase apply) |
| Applications (the 5 deployed services) | `cf push`/`cf deploy` via `cf-deploy.yml`, not Terraform at all |

**Security → Role Collections** (subaccount-level, not CF-scoped) is
worth its own visit — this is where you'd see `ProcureIQ Requester`/
`ProcureIQ Approver`/`ProcureIQ Integration Admin`, each with its role
assigned against the real, live `procurement-core!t700023` app
identity — click into one to see **Users** tab, where you'd actually
assign a real BTP user to a role, the step that makes the XSUAA flow in
`docs/operations/networking-and-request-flow.md` §3 concretely
testable.

## 8. Quick reference: cockpit action → CLI/Terraform equivalent

| I want to... | Cockpit path | Real equivalent this project actually uses |
|---|---|---|
| See if an app is running | Space → Applications | `cf apps` |
| Restart a stopped app | Applications → app → Start | `cf start <app>` |
| Read an app's logs | Applications → app → Logs | `cf logs <app> --recent` |
| See a failed service's real error | Services → Instances → row → `...` → Last Operation Details | the Service Broker Message in `cf service <name>`'s output |
| Create a service by hand | Services → Marketplace → offering → Create | `cf create-service <offering> <plan> <name> -c '<json>'` |
| See/change what's entitled | Entitlements | `btp list accounts/entitlement --subaccount <id>` |
| Provision the whole landing zone from scratch | *(no single screen — this is the point of IaC)* | `terraform apply` — see `docs/concepts/15-terraform-vs-cockpit.md` |
