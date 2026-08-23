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
  # Real gap found and fixed: matching only on environment_type (not
  # state) would silently ADOPT a Kyma instance sitting in a non-OK state
  # (CREATION_FAILED, UPDATE_FAILED, ...) as if it were healthy - a real
  # possibility, since a live apply on this exact project hit `environment
  # instance is in failed state: CREATION_FAILED`. Filtering on
  # `state == "OK"` means a broken instance simply doesn't count as
  # "existing" here - this module will then try to create a fresh one
  # with the same name, and the API itself will reject that with a real,
  # visible name-conflict error rather than this module silently treating
  # a broken instance as good. Not a hidden failure mode either way: fix
  # the broken instance (cockpit or `btp list accounts/environment-
  # instance --subaccount <id>`) once that conflict surfaces.
  existing_kyma = [
    for env in data.btp_subaccount_environment_instances.all.values : env
    if env.environment_type == "kyma" && env.state == "OK"
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
