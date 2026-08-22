# Adaptive, same pattern as modules/cloudfoundry-env: look up what's
# already provisioned, only create what's missing. Confirmed on this
# actual trial subaccount that Kyma is genuinely NOT pre-provisioned
# (cockpit shows "You are currently not using Kyma capabilities" +
# an "Enable Kyma" button) - unlike Cloud Foundry, so the create branch
# is what actually runs here. Kept adaptive anyway, not hardcoded to
# "always create": a real/non-trial subaccount, or this same trial after
# Kyma is manually enabled before Terraform ever runs, both need the
# lookup branch to correctly adopt rather than fail on a duplicate.
data "btp_subaccount_environment_instances" "all" {
  subaccount_id = var.subaccount_id
}

locals {
  existing_kyma = [
    for env in data.btp_subaccount_environment_instances.all.values : env
    if env.environment_type == "kyma"
  ]
  kyma_exists = length(local.existing_kyma) > 0
}

resource "btp_subaccount_environment_instance" "this" {
  count = local.kyma_exists ? 0 : 1

  subaccount_id    = var.subaccount_id
  name             = var.name
  environment_type = "kyma"
  service_name     = "kymaruntime"
  plan_name        = var.plan_name

  # Trial clusters use SAP-managed defaults beyond name/administrators;
  # a full production Kyma module would also take machineType/
  # autoScalerMin/autoScalerMax (confirmed real parameters from
  # SAP-samples/btp-terraform-samples' Kyma module) - omitted here since
  # the trial plan doesn't expose sizing controls.
  parameters = jsonencode({
    name           = var.name
    administrators = var.administrators
  })

  timeouts = {
    create = "60m" # provisioning genuinely takes 15-20 minutes; 60m is headroom, not a guess at actual duration
    update = "35m"
    delete = "60m"
  }
}

locals {
  kyma_id            = local.kyma_exists ? local.existing_kyma[0].id : try(btp_subaccount_environment_instance.this[0].id, null)
  kyma_dashboard_url = local.kyma_exists ? local.existing_kyma[0].dashboard_url : try(btp_subaccount_environment_instance.this[0].dashboard_url, null)
}
