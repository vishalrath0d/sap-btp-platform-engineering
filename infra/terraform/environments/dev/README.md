# environments/dev

The dev environment root module — composes `../../modules/*` against the
real BTP trial subaccount. **Not yet applied** — this project's account
strategy (`PROJECT_CHARTER.md`) is build-first, deploy-after-review, and
apply happens through GitHub Actions once reviewed (see
`../../../.github/workflows/terraform-*.yml`), not from a local machine —
see the root `infra/terraform/README.md` for why.

## What's verified vs. what needs a live account/HCP Terraform to verify

Every resource/attribute name was checked against the actual downloaded
`SAP/btp` provider v1.26.0 schema. `terraform init -backend=false &&
terraform validate` passes (the `-backend=false` skips HCP Terraform
authentication, which needs a real org — see below — while still fully
type-checking every module).

Not yet verified without live credentials:
- `main.tf`'s entitlement `service_name`/`plan_name` values (the
  commonly-documented trial values — the first real `terraform plan` is
  the actual verification step for these).
- `role_collections`'s `xsuaa_xsappname` — genuinely two-phase, see
  `modules/xsuaa`'s comments. Apply once, read the real xsappname from
  `terraform output -json xsuaa_credentials`, set the variable, apply
  again.
- `modules/kyma-environment`'s `plan_name = "trial"` — confirm this is
  actually the plan name this subaccount's Kyma entitlement uses (a real
  applied SAP sample uses hyperscaler-named plans like `"aws"` for
  non-trial landscapes — trial may differ).

## Before the first `terraform plan`

1. **Create a free [HCP Terraform](https://app.terraform.io) account and
   workspace** — this is the remote-state backend `versions.tf`'s `cloud`
   block points at. Create an organization, then a workspace named
   `procureiq-dev` (matching `versions.tf`), set execution mode to
   "Local" or "Remote" depending on whether you want HCP Terraform itself
   or GitHub Actions to run `plan`/`apply` (this project uses GitHub
   Actions — see the workflow files — so "Local" execution mode + a
   workspace API token as a GitHub secret is the right setup, not HCP
   Terraform's own remote execution).
2. Replace `versions.tf`'s `organization = "CHANGE_ME"` with your real
   HCP Terraform org name.
3. In the HCP Terraform workspace, add `btp_username` and `btp_password`
   as **sensitive** workspace variables (Terraform variable category, not
   environment variable category) — this is instead of GitHub secrets,
   since Terraform reads them directly from the workspace regardless of
   which system triggers the run.
4. Confirm the subaccount's exact region and global account subdomain in
   the BTP cockpit (see root `infra/terraform/README.md`).
5. `terraform login` locally (stores an HCP Terraform API token) if you
   want to run `terraform plan` locally to review before pushing — this
   is fine for `plan` (read-only), the project's "don't apply locally"
   guidance is specifically about `apply`.

## Two-phase apply for XSUAA role collections

1. First `terraform apply` — creates the subaccount lookup, entitlements,
   CF + Kyma environments, and the XSUAA instance + binding.
   `role_collections` no-ops (empty for_each) since `xsuaa_xsappname` is
   still null.
2. Read the real xsappname: `terraform output -json xsuaa_credentials`
   (sensitive — don't paste it anywhere public) and extract `xsappname`.
3. Set `xsuaa_xsappname` (as a workspace variable or `-var`), apply again
   — now `role_collections` actually creates the three collections.
