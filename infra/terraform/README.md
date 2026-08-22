# infra/terraform

Provisions the ProcureIQ landing zone on the real BTP trial subaccount —
entitlements, Cloud Foundry + Kyma environments, XSUAA, and (once reachable)
the Destination service entry mirroring the local Cloud Connector
simulation. **Written and syntax-validated, not yet applied** — see
`PROJECT_CHARTER.md`'s account strategy: build first, deploy after review.

## What's verified vs. what needs a live account to verify

Every resource/attribute name in this module was checked against the
**actual downloaded `SAP/btp` provider v1.26.0 schema** (`terraform
providers schema -json`), not written from memory or assumed — see the
project's session notes for how. `terraform validate` passes.

What *couldn't* be verified without live credentials (documented inline,
not hidden):
- **`entitlements.tf`**'s exact `service_name`/`plan_name` values for
  Cloud Foundry, Kyma, and HANA Cloud trial entitlements — these are the
  commonly-documented values, but the trial catalog is the actual source
  of truth. The first real `terraform plan` is expected to be the
  verification step; a wrong value fails loudly against the API rather
  than silently misconfiguring something.
- **`role_collections.tf`**'s `xsuaa_xsappname` — genuinely can't be known
  before `security.tf`'s XSUAA service binding is created once (XSUAA
  assigns it at bind time). This module is deliberately two-phase: apply
  once for the instance+binding, read the real xsappname out of
  `terraform output -json xsuaa_credentials`, set it, apply again.

## Before the first `terraform plan`

1. Confirm the subaccount's exact **region** technical ID in the cockpit
   (Overview page) — `variables.tf` defaults to `us10` for "US East (VA) -
   AWS," double-check it matches.
2. Confirm the **global account subdomain** (Account Explorer) — for a
   fresh trial it's usually the same as the subaccount subdomain, but
   don't assume.
3. Set credentials as environment variables, never in a committed file:
   ```bash
   export TF_VAR_btp_username="you@example.com"
   export TF_VAR_btp_password="..."
   ```
4. Copy `terraform.tfvars.example` → `terraform.tfvars` (gitignored) and
   fill in the non-secret values.
5. `terraform init && terraform plan` — read the plan output carefully
   before `apply`, especially for the entitlement values flagged above.

## Files

| File | Provisions |
|---|---|
| `subaccount.tf` | Looks up the existing trial subaccount (data source — a trial can't create a second one) |
| `entitlements.tf` | Cloud Foundry, Kyma, HANA Cloud trial quotas |
| `environments.tf` | The actual CF org and Kyma cluster |
| `security.tf` | XSUAA service instance + binding, using `services/procurement-core/xs-security.json` as the single source of truth for the role model |
| `role_collections.tf` | Explicit IaC role collections (the alternative to xs-security.json's own auto-provisioning — both are documented, this file explains why both exist) |
| `destinations.tf` | The real `btp_subaccount_destination` counterpart to the local Cloud Connector simulation — commented out until `legacy-erp-gateway` is actually reachable from BTP |

## Known limitations (honesty notes)

- No remote state backend configured yet — local state only, fine for a
  single-operator trial, not how a real team would run this.
- No `dev`/`qa`/`prod` *subaccount* separation — the trial only provides
  one subaccount total; `var.environment` labels resources within it
  rather than targeting genuinely separate subaccounts. Real multi-env
  promotion (`transport/cloud-transport-management`) needs a paid
  landscape to demonstrate for real.
- Kyma provisioning genuinely takes 15-20 minutes; `environments.tf`'s
  `kyma` resource will make `apply` sit for a while — expected, not a hang.
