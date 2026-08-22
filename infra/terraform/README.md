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
| `XSUAA_XSAPPNAME` | Leave unset until the two-phase apply below reaches step 2 |

Plus, in HCP Terraform itself: create the `procureiq-dev` workspace via
the **CLI-Driven Workflow** (not "Version control" — that would have HCP
Terraform trigger its own runs from the repo, duplicating what GitHub
Actions already does; not "API-Driven" either, since the CLI via
`hashicorp/setup-terraform` is what's actually driving this), then set
its **Execution Mode to Local** in Settings → General.

Also confirm the subaccount's exact region and global account subdomain
in the BTP cockpit; update `environments/dev/terraform.tfvars` if they
differ from what's there.

## Two-phase apply for XSUAA role collections

1. First `terraform apply` — creates the subaccount lookup, entitlements,
   CF + Kyma environments, and the XSUAA instance + binding.
   `role_collections` no-ops (empty for_each) since `xsuaa_xsappname` is
   still null.
2. Read the real xsappname: `terraform output -json xsuaa_credentials`
   (sensitive — don't paste it anywhere public) and extract `xsappname`.
3. Set it as the `XSUAA_XSAPPNAME` GitHub secret, wire it into
   `terraform-apply.yml` as `TF_VAR_xsuaa_xsappname`, apply again — now
   `role_collections` actually creates the three collections.

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
