# Adaptive: look up what's already provisioned, only create what's
# missing - works correctly on BOTH a trial (Cloud Foundry comes
# pre-provisioned and can't be deleted or recreated - confirmed live:
# `cf delete-org` returned "not authorized") AND a fresh/real subaccount
# (no CF yet, so this creates it automatically instead of silently
# no-op'ing or erroring).
data "btp_subaccount_environment_instances" "all" {
  subaccount_id = var.subaccount_id
}

locals {
  # Same real gap fixed here as modules/kyma-env - matched only on
  # environment_type before, never on state, so a CF org sitting in a
  # non-OK state would have been silently adopted as if healthy. Filtering
  # on state == "OK" means a broken org doesn't count as "existing" -
  # this module tries to create a fresh one instead, and the API's own
  # real name-conflict error surfaces the problem rather than this module
  # hiding it.
  existing_cloudfoundry = [
    for env in data.btp_subaccount_environment_instances.all.values : env
    if env.environment_type == "cloudfoundry" && env.state == "OK"
  ]
  cloudfoundry_exists = length(local.existing_cloudfoundry) > 0
}

resource "btp_subaccount_environment_instance" "this" {
  count = local.cloudfoundry_exists ? 0 : 1

  subaccount_id    = var.subaccount_id
  name             = var.org_name
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "standard"
  landscape_label  = var.landscape_label

  parameters = jsonencode({
    instance_name = var.org_name
    org_name      = var.org_name
  })
}

locals {
  # Whichever branch actually has the data - the pre-existing lookup, or
  # the one this module just created.
  cloudfoundry_id            = local.cloudfoundry_exists ? local.existing_cloudfoundry[0].id : try(btp_subaccount_environment_instance.this[0].id, null)
  cloudfoundry_dashboard_url = local.cloudfoundry_exists ? local.existing_cloudfoundry[0].dashboard_url : try(btp_subaccount_environment_instance.this[0].dashboard_url, null)
  cloudfoundry_org_name      = local.cloudfoundry_exists ? local.existing_cloudfoundry[0].name : try(btp_subaccount_environment_instance.this[0].name, null)
}
