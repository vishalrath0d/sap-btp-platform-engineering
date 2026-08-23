# infra/terraform

Provisions the ProcureIQ landing zone on the real BTP trial subaccount.
**Written and validated, not yet applied** — this project's account
strategy (`PROJECT_CHARTER.md`) is build-first, deploy-after-review, and
apply happens through GitHub Actions once reviewed, not from a local
machine — see "Why GitHub Actions, not local apply" below.

## Structure — corrected to match a real, working convention

```
infra/terraform/
├── main.tf, variables.tf, outputs.tf,     # ONE shared root module - every
│   provider.tf, versions.tf                environment uses these unchanged
├── modules/                               # reusable, no environment-specific values
│   ├── subaccount/         (data lookup - a trial can't create a second one)
│   ├── entitlements/        (for_each over a list, real pattern from SAP-samples)
│   ├── cloudfoundry-env/
│   ├── kyma-env/
│   ├── xsuaa/                (service instance + binding)
│   ├── role-collections/     (reads xsuaa's output directly - single apply, see that module)
│   └── destination/          (Cloud Connector counterpart, not yet instantiated)
└── environments/
    ├── dev/terraform.tfvars    # ONLY variable values - real, usable today
    ├── qa/terraform.tfvars     # ONLY variable values - stub, no qa subaccount exists yet
    └── prod/terraform.tfvars   # ONLY variable values - same reason
```

**This was corrected from an earlier, wrong structure** that duplicated
`main.tf`/`variables.tf`/`outputs.tf`/`provider.tf`/`versions.tf` inside
each `environments/<env>/` directory — meaning every environment would
have needed its own copy of the same module-composition logic, drifting
out of sync over time. Fixed to mirror the real, working pattern from
`sm-infraforge/langfuse` (checked directly, not assumed): one shared root
module, environment folders holding *only* a `terraform.tfvars`.

## State isolation: one shared config, one HCP Terraform workspace per environment

`versions.tf`'s `cloud {}` block is deliberately empty — `organization`
and `workspaces.name` come from the `TF_CLOUD_ORGANIZATION` and
`TF_WORKSPACE` environment variables instead (confirmed against
HashiCorp's own docs: when a `cloud` block argument is omitted, Terraform
reads the matching env var; the workspace must already exist). CI sets
these per job, so the exact same `.tf` files serve every environment.

Worth being explicit about since it doesn't map 1:1 onto the reference
project's S3-backend pattern: **HCP Terraform's state-isolation unit is a
workspace**, not a key inside one shared workspace the way S3 works —
there's no "one workspace, many key-namespaced state files" option in HCP
Terraform. So `dev`/`qa`/`prod` become **three separate HCP Terraform
workspaces** — `procureiq-dev`, `procureiq-qa`, `procureiq-prod` — each
with its own state. `procureiq` is the project-name prefix (the same role
`PROJECT` plays in the reference project's Jenkinsfile), `-<env>` is the
per-environment suffix. You need to create each workspace in HCP Terraform
up front (just `dev` for now is fine — add `qa`/`prod` when there's a
real landscape to point them at).

**Each workspace's Execution Mode must be "Local"** — this means HCP
Terraform only stores state; GitHub Actions runs the actual `plan`/
`apply`. One consequence worth knowing before it's confusing: **Local-
execution-mode workspaces don't have a Variables tab at all** — HCP
Terraform doesn't evaluate workspace variables for local runs. Credentials
have to reach the Terraform CLI directly as `TF_VAR_*` environment
variables from wherever the CLI actually runs (GitHub Actions) — see the
next section.

## Why GitHub Actions, not local `apply`

Applying Terraform from a laptop against infrastructure a public GitHub
repo's CI is also meant to manage invites exactly the kind of drift and
untracked-changes problems Terraform exists to prevent — the state of
truth should be "what the last CI run applied," not "whatever was last run
locally, maybe by someone else's laptop." `.github/workflows/terraform-
plan.yml` and `terraform-apply.yml` (repo root — GitHub only discovers
workflows there) run `plan` on every PR touching `infra/terraform/**` and
`apply` only on an explicit manual trigger against the `dev`
GitHub Environment (which can require reviewer approval) — never
automatically on push, matching this project's "deploy after review"
instruction.

## Before the first `terraform plan` — GitHub Actions secrets needed

All five set on the GitHub repo (Settings → Secrets and variables →
Actions), never in a committed file:

| Secret | Value |
|---|---|
| `TF_API_TOKEN` | An HCP Terraform API token (User Settings → Tokens) |
| `TF_CLOUD_ORGANIZATION` | Your HCP Terraform org name (e.g. `vishalrath0d-tf-org`) |
| `BTP_USERNAME` | SAP Universal ID used to log into the BTP trial |
| `BTP_PASSWORD` | Its password |

Plus, in HCP Terraform itself: create the `procureiq-dev` workspace via
the **CLI-Driven Workflow** (not "Version control" — that would have HCP
Terraform trigger its own runs from the repo, duplicating what GitHub
Actions already does; not "API-Driven" either, since the CLI via
`hashicorp/setup-terraform` is what's actually driving this), then set
its **Execution Mode to Local** in Settings → General.

Also confirm the subaccount's exact region and global account subdomain
in the BTP cockpit; update `environments/dev/terraform.tfvars` if they
differ from what's there.

## XSUAA role collections — single apply, not two

`role_collections` reads the real xsappname directly from
`module.xsuaa.credentials` (decoded inline in
`modules/role-collections/main.tf`) rather than needing it supplied as a
separate variable. An earlier version of this module required a manual
two-phase apply (apply once, read `terraform output`, set a variable,
apply again) — that was a design mistake in how the module used
`for_each`, not a real Terraform limitation: **a resource's *attributes*
can depend on values only known after another resource is created in the
same apply** (completely standard — e.g. a subnet ID referencing a VPC
created moments earlier in the same run); only `for_each`/`count`
genuinely cannot. The fix was making `for_each` fixed (always the 3 role
collections) and only the `role_template_app_id` *attribute* depend on
the XSUAA binding's output. One `terraform apply` now creates the
subaccount lookup, entitlements, CF/Kyma environments, XSUAA instance +
binding, *and* the role collections referencing it, correctly sequenced,
in a single run.

## What's verified vs. what needs a live account to verify

Every resource/attribute name in every module was checked against the
actual downloaded `SAP/btp` provider v1.26.0 schema, not written from
memory. `terraform init -backend=false && terraform validate` passes
(the `-backend=false` skips the backend template's incomplete
`organization`/`workspaces.name`, which need real CI-supplied values to
resolve, while still fully type-checking every module).

**Update — verified live**: a real `terraform plan` against the actual
HCP Terraform workspace and BTP trial credentials ran clean
(`Plan: 6 to add, 0 to change, 0 to destroy`) after fixing several real
issues a schema-only validate couldn't catch — see git history on the
`terraform/first-plan-run` branch/PR for the full sequence:
`data.btp_subaccount` needs `region` alongside `subdomain` (not just
`subdomain` — the schema marks both individually optional, the API
requires both together); the real subaccount/global-account subdomains
differed from what was assumed (`4cbf0c12trial` vs. `4cbf0c12trial-ga` —
confirmed directly in the cockpit, not guessed twice); the trial's
default Cloud Foundry org **cannot be deleted** (`cf delete-org` →
"not authorized"), so `modules/cloudfoundry-env` and `modules/kyma-env`
now look up what's already provisioned and only create what's actually
missing (`count = exists ? 0 : 1`) — the same module works correctly on
this trial (adopts CF, creates Kyma, since Kyma is confirmed not yet
enabled) and on a fresh/real subaccount (creates both); `depends_on` on a
module forces its data sources to defer to apply-time, which breaks
`count` evaluation — removed, with the real practical implication
documented (a genuinely fresh subaccount with zero entitlements might
need two applies the first time, same class of issue as any resource
whose count depends on another resource's existence).

**Correction to the paragraph above, from a real `terraform apply` run**:
"the live plan proposed creating them without error" was **not** the same
as "confirmed correct" — `terraform plan` never validates entitlement
`service_name`/`plan_name` against the live catalog, only `apply` does,
and the first real `apply` proved several of these wrong: `cloudfoundry/
standard` and `hana-cloud-trial/hana-cloud-trial` both failed with *"the
global account is not entitled to this service plan"* (this global
account's real entitlement for each is a different plan name, or already
pre-granted through a different mechanism entirely — not yet confirmed
which); `kymaruntime/trial` failed separately with *"a quota was not set
in the amount parameter"* — a config gap, not a wrong name (its
entitlement `category` is `SERVICE`, which requires an explicit numeric
`amount`; fixed in `main.tf`).

The real, more useful fix wasn't guessing better names — it was
recognizing that a trial account's default entitlements are typically
**already pre-granted automatically**, so Terraform trying to *create* a
fresh entitlement for something already granted is the wrong operation,
independent of whether the guessed name happens to be right. `modules/
entitlements` is now adaptive, same pattern as `cloudfoundry-env`/
`kyma-env`: look up what's already entitled (`data
"btp_subaccount_entitlements"`), only create what's genuinely missing.
This is correct on a trial (silently adopts the pre-granted ones,
whatever their real plan name is) and correct on a real/paid account
(nothing is pre-granted, so it creates everything) — the same code, not
two different code paths for the two account types.

`modules/role-collections` needed the identical fix for a different
reason: XSUAA auto-creates a role collection (`creationType: XSSECURITY`)
for every role template in `xs-security.json` the moment its service
instance is created — by the time this module tried to create the same
three role collections fresh, they already existed, and the API refused
to change their `creationType` to `admin`. Now adaptive too (`data
"btp_subaccount_role_collections"`), with one honestly-stated residual
edge case: on a genuinely fresh subaccount where XSUAA and these role
collections are *both* created for the first time in the same apply, the
very first run might still hit this once (the lookup's plan-time snapshot
predates XSUAA's auto-creation) — re-running `apply` a second time
resolves it, the same class of "fresh subaccount might need two applies"
note already given above for entitlements-then-environments.

**Resolved**: `abap`/`integration-suite` turned out to be a naming
problem too, not a real "not entitled" rejection — `btp list accounts/
entitlement --subaccount <id>` (real command output, not guessed) showed
both are already granted, just under different real names:
`abap-trial`/`shared` and `integrationsuite-trial`/`trial` (confirmed
against the cockpit's Entitlements → Add Service Plans catalog too — both
show `100%` already assigned). Same for `cloudfoundry` (real:
`cloudfoundry`/`trial`, not `standard`) and the HANA entitlement (real:
`hana`/`hdi-shared`, quota 10 — `hana-cloud-trial` isn't a real
entitlement name at all; `procurement-core/mta.yaml`'s HDI container
resource had the identical wrong name and was fixed at the same time,
before it could fail a real `cf deploy` later). `main.tf`'s
`entitlements` module call now uses all five real, live-confirmed values
— the next `terraform plan`/`apply` should show every entitlement
adopted (0 created), with only the Kyma environment instance itself
genuinely needing to be (re-)created.

## Known limitations (honesty notes)

- No genuinely separate `qa`/`prod` subaccounts yet — the trial only
  provides one. Real multi-env promotion needs a paid landscape.
- **Trial Kyma clusters can't be created via `terraform apply` at all** —
  confirmed via two real, consecutive `CREATION_FAILED` apply failures
  (both in ~40s, both a fast rejection, not real provisioning): the
  cockpit's own Kyma tab shows the real reason ("To request a trial Kyma
  cluster, follow the instructions in Getting Started with a Trial Kyma
  Instance"), matching a real GitHub issue on `SAP/terraform-provider-btp`
  reporting the identical "unauthorized" behavior for trial Kyma via this
  API. The one-time fix is a manual cockpit step (Kyma Environment tab →
  "Enable Kyma") — `modules/kyma-env`'s adaptive lookup then correctly
  adopts it on the next plan/apply, no Terraform change needed for that
  half. Also confirmed in SAP's own docs while chasing this down: a trial
  Kyma cluster auto-expires and is deleted 14 days after creation.
- Kyma provisioning genuinely takes 15-25 minutes once actually
  triggered (via the cockpit, per above — not via `apply`, which fails
  fast on trial); expect to wait there.
- The adaptive CF/Kyma modules have only been proven against *this*
  trial's actual state (CF pre-existing, Kyma not) — the "creates on a
  fresh subaccount" half of the claim is architecturally sound and
  follows directly from how the lookup/count logic works, but hasn't
  been run against a genuinely empty subaccount to observe the create
  path fire for real.
