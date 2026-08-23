# Adaptive, same reasoning as modules/cloudfoundry-env and modules/kyma-env
# (look up what's real, create only what's missing) - now applied here
# too, after a real live apply proved it was needed: several of this
# module's "confirmed correct" entitlement guesses
# (cloudfoundry/standard, hana-cloud-trial/hana-cloud-trial) were WRONG
# for this trial's actual global-account catalog ("terraform plan" never
# validates against the live catalog, only apply does - the earlier
# "plan succeeded, so these are confirmed correct" claim in this
# project's own README turned out not to mean what it was assumed to
# mean, corrected there too).
#
# The deeper fact this surfaced, not just a wrong string: a trial
# account's default entitlements (cloudfoundry, hana-cloud-trial,
# kymaruntime) are typically ALREADY pre-granted automatically by SAP -
# Terraform trying to CREATE a fresh entitlement for something already
# granted is the wrong operation entirely, independent of whether the
# plan_name guess happens to be right. A real/paid account behaves the
# opposite way: nothing is pre-granted, every entitlement genuinely needs
# Terraform to create it. This module now handles both with the same
# code: look up what's already entitled, only create what's actually
# missing - correct on a trial (skips the pre-granted ones, whatever
# their exact real plan_name is) and correct on a real account (creates
# everything, since the lookup finds nothing pre-existing).
data "btp_subaccount_entitlements" "all" {
  subaccount_id = var.subaccount_id
}

locals {
  existing_keys = toset([
    for e in data.btp_subaccount_entitlements.all.values :
    "${e.service_name}/${e.plan_name}"
  ])

  to_create = {
    for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e
    if !contains(local.existing_keys, "${e.service_name}/${e.plan_name}")
  }
}

# for_each-over-a-map pattern confirmed against a real applied example in
# SAP-samples/btp-terraform-samples (released/usecases/dev_test_prod_setup) -
# not invented for this project. Gated on `local.to_create`, not
# `var.entitlements` directly - the one change from the original version.
# No depends_on here (same reasoning documented on cloudfoundry-env/
# kyma-env): this data source has no forced dependency on any other
# resource in this apply, so it resolves during plan, keeping `for_each`
# computable at plan time - adding depends_on would defer it to apply-time
# and break that, the exact bug already found and fixed for CF/Kyma.
resource "btp_subaccount_entitlement" "this" {
  for_each = local.to_create

  subaccount_id = var.subaccount_id
  service_name  = each.value.service_name
  plan_name     = each.value.plan_name
  amount        = each.value.amount
}
