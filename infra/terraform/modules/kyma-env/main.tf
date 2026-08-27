# Adaptive, same pattern as modules/cloudfoundry-env: look up what's
# already provisioned, only create what's missing.
#
# Real, structural finding, confirmed twice over on this trial - once via
# two live `terraform apply` failures (`environment instance is in failed
# state: CREATION_FAILED`, both in ~40s - too fast to be real
# provisioning, which takes 15-25 minutes), then again by trying the
# cockpit's own native "Enable Kyma" wizard directly (not Terraform at
# all) and hitting the identical failure there too: **this trial account
# does not have self-service Kyma provisioning at all, through any path**.
# SAP's own real documentation ("Getting Started with a Trial Kyma
# Instance", fetched via SAP-docs' GitHub mirror since the live Help
# Portal page is JS-rendered and doesn't return real content to a plain
# fetch) confirms this is by design, not a bug or a stale-docs situation:
# a trial Kyma instance must be REQUESTED from SAP - open a support
# ticket for component BC-CP-XF-KYMA, or email kyma@sap.com with subject
# "SAP BTP, Kyma Runtime Trial Request" (Global Account ID, Subaccount
# ID, administrator emails, reason for request) - and SAP reviews each
# request "on a case-by-case basis within one month," may decline
# incomplete/non-compliant ones. Not fixable from Terraform's side, or
# from any code in this repo - a genuinely account-side, human-approval
# gated step, a stronger version of the same class of thing this project
# already documents for ABAP RAP/Integration Suite authoring.
#
# What this module still does correctly once that approval eventually
# lands and SAP provisions the cluster: this module's adaptive lookup
# (below) will find it and ADOPT it (0 create needed) on the next plan/
# apply - no code change needed for that half. The `resource` block below
# stays real and correct for a non-trial/paid subaccount, where this
# approval gate is not expected to apply.
#
# Also worth knowing, confirmed in SAP's own docs while researching this:
# trial Kyma clusters auto-expire and are deleted 14 days after creation -
# not a one-time setup, a real recurring operational fact for trial use.
#
# Addendum, 2026-08-27, once approval actually landed: the adopt-lookup
# below turned out NOT to work on this trial either - the data source it
# queries genuinely doesn't return the cluster SAP provisioned through
# its manual approval process (confirmed via a temporary debug output,
# see git history). Root main.tf's module.kyma_env call now hardcodes
# count=0 unconditionally rather than relying on this module's adopt-
# vs-create logic to sort it out - this file's logic below is kept as
# real, correct Terraform for a subaccount where the data source DOES
# see Kyma (a non-trial account, or self-service-enabled Kyma), not
# deleted, just not what's driving this trial's actual count anymore.
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
