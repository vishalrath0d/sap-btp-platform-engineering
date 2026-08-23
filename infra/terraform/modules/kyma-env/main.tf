# Adaptive, same pattern as modules/cloudfoundry-env: look up what's
# already provisioned, only create what's missing.
#
# Real, structural finding from two consecutive live apply failures on
# this trial (both `environment instance is in failed state:
# CREATION_FAILED`, both in ~40s - too fast to be real provisioning,
# which takes 15-25 minutes): **trial Kyma clusters cannot be created
# through this resource's generic environment-instance API at all** - the
# cockpit's own Kyma Environment tab surfaced the real reason Terraform's
# error didn't: "To request a trial Kyma cluster, follow the instructions
# in Getting Started with a Trial Kyma Instance" - a cockpit-only "Enable
# Kyma" action, confirmed against SAP's own docs and a matching real
# GitHub issue on SAP/terraform-provider-btp reporting the identical
# "unauthorized" behavior for trial Kyma creation via this API. Not a
# code bug, not fixable from Terraform's side - the same class of
# genuinely account-side manual step this project already documents for
# ABAP RAP/Integration Suite authoring.
#
# What this module still does correctly: once a trial Kyma cluster is
# created via the cockpit's "Enable Kyma" flow, this module's adaptive
# lookup (below) will find it and ADOPT it (0 create needed) on the next
# plan/apply - no code change needed for that half, only the initial
# creation needs the manual cockpit step. The `resource` block below stays
# real and correct for a non-trial/paid subaccount, where this API
# restriction is not expected to apply.
#
# Also worth knowing, confirmed in SAP's own docs while researching this:
# trial Kyma clusters auto-expire and are deleted 14 days after creation -
# not a one-time setup, a real recurring operational fact for trial use.
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
