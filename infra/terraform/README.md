# infra/terraform

Provisions the ProcureIQ landing zone on the real BTP trial subaccount.
**Written and validated, not yet applied** — this project's account
strategy (`PROJECT_CHARTER.md`) is build-first, deploy-after-review, and
apply happens through GitHub Actions once reviewed, not from a local
machine — see "Why GitHub Actions, not local apply" below.

## Structure

```
infra/terraform/
├── modules/                     # reusable, no environment-specific values
│   ├── subaccount/                (data lookup - a trial can't create a second one)
│   ├── entitlements/               (for_each over a list, real pattern from SAP-samples)
│   ├── cloudfoundry-environment/
│   ├── kyma-environment/
│   ├── xsuaa/                      (service instance + binding)
│   ├── role-collections/           (two-phase, see modules/xsuaa's comments)
│   └── destination/                (Cloud Connector counterpart, not yet instantiated)
└── environments/                # root modules, one per promotion stage
    ├── dev/                        # the only one that's real right now
    ├── qa/                         # stub - needs a paid multi-subaccount landscape
    └── prod/                       # stub - same reason
```

This mirrors the real pattern found in `SAP-samples/btp-terraform-samples`
(`modules/` + `usecases/` — this project's `environments/` plays the same
role as their `usecases/`) rather than the flat single-directory layout
this module started with before a review caught it.

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

## What's verified vs. what needs a live account to verify

Every resource/attribute name in every module was checked against the
actual downloaded `SAP/btp` provider v1.26.0 schema (`terraform providers
schema -json`), not written from memory. `terraform init -backend=false &&
terraform validate` passes for `environments/dev`.

What couldn't be verified without live credentials or an HCP Terraform
account — see `environments/dev/README.md`'s full checklist:
- Exact entitlement `service_name`/`plan_name` values (commonly-documented
  trial values; first real `plan` is the verification step).
- The real XSUAA `xsappname` for role collections (assigned at bind time —
  genuinely two-phase apply, not an oversight).
- Kyma's exact trial `plan_name`.

## Remote state

`environments/dev/versions.tf` uses an HCP Terraform `cloud` block for
remote state — required for the GitHub-Actions-apply approach to work at
all (GitHub-hosted runners are ephemeral; state has to live somewhere
outside the runner), and it also keeps sensitive output values (XSUAA
credentials) out of a public repo's git history. Needs a free HCP
Terraform account + workspace — see `environments/dev/README.md`.

## Known limitations (honesty notes)

- No genuinely separate `qa`/`prod` subaccounts yet — the trial only
  provides one. Real multi-env promotion needs a paid landscape.
- Kyma provisioning genuinely takes 15-20 minutes; expect `apply` to sit
  on that resource for a while.
