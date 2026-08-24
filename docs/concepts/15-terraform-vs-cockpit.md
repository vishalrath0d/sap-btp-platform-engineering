# Terraform vs. the BTP cockpit — the same landing zone, two ways

Every real resource `infra/terraform` provisions can also be created by
hand in the BTP cockpit — Terraform isn't calling some separate,
IaC-only API. Both paths hit the exact same BTP/Cloud Foundry REST APIs
underneath; Terraform just does it declaratively, from a file, with a
plan you can review before it runs, instead of a human clicking through
screens from memory each time.

## Why this project uses Terraform at all, on a single trial subaccount

With one subaccount and one person, the click-through cost of doing this
by hand once is genuinely low — the real case for IaC here isn't
"clicking is hard," it's:
- **A reviewable plan before anything changes** (`terraform plan`,
  gated behind a GitHub Environment with optional required reviewers) —
  no cockpit screen shows you "here's exactly what's about to change"
  before you click.
- **Idempotent re-runs.** Run `terraform apply` again with nothing
  changed and nothing happens — re-clicking through the same cockpit
  screens either errors ("already exists") or silently does nothing,
  and you can't tell which without checking first. This project's
  modules are explicitly *adaptive* for this reason (see below).
- **A second environment is a variable file, not a memory test.**
  `environments/qa/terraform.tfvars` exists today, unused, precisely so
  that standing up a `qa` subaccount later means filling in one file,
  not remembering (or re-documenting) every click that created `dev`.

## The real per-resource mapping — go here for the how-to

`infra/terraform/README.md` has the actual, detailed walkthrough for
every module: what it creates, the exact cockpit screens to do it by
hand instead, and — importantly — **which resources this project
deliberately does NOT manage via Terraform**, and why (the HANA Cloud
database and the XSUAA/HDI-container instances created by `procurement-
core`'s own MTA deploy, not Terraform — a real scoping boundary, not an
oversight). `docs/operations/btp-cockpit-navigation.md` is the
complementary "where do I even find this in the cockpit" map, organized
by screen instead of by resource.

## The general pattern, if you're doing this on a BTP account of your own

1. **Global account → subaccount** exists first, always by hand (cockpit
   or `btp create accounts/subaccount`) — Terraform's own
   `modules/subaccount` is a `data` lookup here, not a `resource`,
   because a trial can't have a second subaccount to create.
2. **Entitlements** — grant your subaccount permission to use a
   service/plan at all. Cockpit: Entitlements → Configure Entitlements →
   Add Service Plans. Terraform: `btp_subaccount_entitlement` (this
   project's `modules/entitlements`).
3. **Environment instances** (Cloud Foundry org, Kyma cluster) —
   cockpit: the relevant "Enable"/"Create" wizard under Cloud Foundry or
   Kyma. Terraform: `btp_subaccount_environment_instance` (this
   project's `modules/cloudfoundry-env`/`modules/kyma-env`).
4. **Service instances** *at the subaccount level* (Service Manager,
   platform-agnostic — e.g. this project's XSUAA-if-it-weren't-a-
   duplicate case) — cockpit: Instances & Subscriptions, or a
   service-specific screen. Terraform: `btp_subaccount_service_instance`.
5. **Service instances scoped to one CF space** — cockpit: that space's
   own Service Marketplace → Create. **Terraform's `SAP/btp` provider
   cannot do this at all** — no CF-space/platform-scoping concept exists
   in its schema (confirmed by exhaustively checking it, not assumed —
   see `infra/terraform/README.md`). This is where `cf create-service`
   (via the CF CLI, in this project's `cf-deploy.yml`) is the correct
   tool, not a Terraform gap to work around.
6. **App deployment itself** (`cf push`/`cf deploy`) is never a
   Terraform concern in any setup — Terraform provisions the landing
   zone the app runs *in*; a separate deploy pipeline pushes the app
   *into* it. See `docs/operations/networking-and-request-flow.md` for
   why these are genuinely two different lifecycles in this project.
