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
│   ├── role-collections/     (two-phase, see modules/xsuaa's comments)
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

## State isolation: one shared backend, parameterized per environment

`versions.tf`'s `backend "remote"` block is a **template**, not real
config — CI overrides `organization`/`workspaces.name` via
`-backend-config` flags at `terraform init` time. This mirrors exactly
what the reference project does with its S3 backend (`backend.tf` is a
placeholder there too; Jenkins's `terraformInit.groovy` supplies the real
`bucket`/`key`/`region` per environment, with `key =
"{project}/{environment}/terraform.tfstate"`).

The one real difference, worth being explicit about since it doesn't map
1:1: **HCP Terraform's state-isolation unit is a workspace**, not a key
inside one shared workspace the way S3 works — there's no "one workspace,
many key-namespaced state files" option in HCP Terraform the way there is
in S3. So `dev`/`qa`/`prod` become **three separate HCP Terraform
workspaces** — `procureiq-dev`, `procureiq-qa`, `procureiq-prod` — each
with its own state, each fed by the matching `environments/<env>/
terraform.tfvars` plus its own `btp_username`/`btp_password`/
`xsuaa_xsappname` workspace variables. `procureiq` is the project-name
prefix (the `PROJECT` value in the reference project's Jenkinsfile),
`-<env>` is the per-environment suffix — you do need to create all three
workspaces in HCP Terraform up front (or just `dev` for now, add
`qa`/`prod` when there's a real landscape to point them at), there's no
way to get one workspace to transparently hold three environments' state.

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

## Before the first `terraform plan`

1. Create a free [HCP Terraform](https://app.terraform.io) account + an
   organization, then a `procureiq-dev` workspace (execution mode:
   "Local" — GitHub Actions runs `plan`/`apply`, not HCP Terraform's own
   remote execution).
2. In that workspace, add `btp_username` and `btp_password` as
   **sensitive Terraform variables** (not environment variables).
3. Set `TF_API_TOKEN` (an HCP Terraform API token) as a GitHub Actions
   secret, and put the real organization name in `versions.tf` — or,
   better, pass it via `-backend-config` in the workflow alongside
   `workspaces.name`, so `versions.tf` never needs a real value hardcoded
   at all.
4. Confirm the subaccount's exact region and global account subdomain in
   the BTP cockpit; update `environments/dev/terraform.tfvars`.

## Two-phase apply for XSUAA role collections

1. First `terraform apply` — creates the subaccount lookup, entitlements,
   CF + Kyma environments, and the XSUAA instance + binding.
   `role_collections` no-ops (empty for_each) since `xsuaa_xsappname` is
   still null.
2. Read the real xsappname: `terraform output -json xsuaa_credentials`
   (sensitive — don't paste it anywhere public) and extract `xsappname`.
3. Set `xsuaa_xsappname` as an HCP Terraform workspace variable, apply
   again — now `role_collections` actually creates the three collections.

## What's verified vs. what needs a live account to verify

Every resource/attribute name in every module was checked against the
actual downloaded `SAP/btp` provider v1.26.0 schema, not written from
memory. `terraform init -backend=false && terraform validate` passes
(the `-backend=false` skips the backend template's incomplete
`organization`/`workspaces.name`, which need real CI-supplied values to
resolve, while still fully type-checking every module).

Not yet verified without live credentials:
- Exact entitlement `service_name`/`plan_name` values (commonly-documented
  trial values; first real `plan` is the verification step).
- Kyma's exact trial `plan_name`.

## Known limitations (honesty notes)

- No genuinely separate `qa`/`prod` subaccounts yet — the trial only
  provides one. Real multi-env promotion needs a paid landscape.
- Kyma provisioning genuinely takes 15-20 minutes; expect `apply` to sit
  on that resource for a while.
