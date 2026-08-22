# One shared root module for every environment - dev/qa/prod differ only
# by which environments/<env>/terraform.tfvars file CI passes via
# `-var-file`, never by duplicated composition logic here. See this
# folder's README for the full reasoning (and why this was a correction
# from an earlier, wrong per-environment-directory-with-duplicated-.tf
# structure).

module "subaccount" {
  source    = "./modules/subaccount"
  subdomain = var.subaccount_subdomain
  region    = var.region
}

module "entitlements" {
  source        = "./modules/entitlements"
  subaccount_id = module.subaccount.id

  entitlements = [
    { service_name = "cloudfoundry", plan_name = "standard" },
    { service_name = "kymaruntime", plan_name = "trial" },
    { service_name = "hana-cloud-trial", plan_name = "hana-cloud-trial" },
  ]
}

module "cloudfoundry_env" {
  # Lookup, not creation - the trial's default CF org can't be deleted
  # (confirmed: `cf delete-org` returned "not authorized"), so this adopts
  # the existing one. See modules/cloudfoundry-env/main.tf's commented-out
  # resource block for the creation path, kept for when it's actually needed.
  source        = "./modules/cloudfoundry-env"
  subaccount_id = module.subaccount.id
}

module "kyma_env" {
  source         = "./modules/kyma-env"
  subaccount_id  = module.subaccount.id
  name           = "procureiq-kyma-${var.environment}"
  plan_name      = "trial"
  administrators = var.kyma_administrators

  depends_on = [module.entitlements]
}

module "xsuaa" {
  source                = "./modules/xsuaa"
  subaccount_id         = module.subaccount.id
  name_prefix           = "procurement-core-${var.environment}"
  xs_security_json_path = "${path.module}/../../services/procurement-core/xs-security.json"
}

module "role_collections" {
  source          = "./modules/role-collections"
  subaccount_id   = module.subaccount.id
  xsuaa_xsappname = var.xsuaa_xsappname

  role_collections = [
    { name = "ProcureIQ Requester", description = "Business users who raise Purchase Requisitions", role_template_name = "Requester" },
    { name = "ProcureIQ Approver", description = "Approves submitted Purchase Requisitions", role_template_name = "Approver" },
    { name = "ProcureIQ Integration Admin", description = "Runs the legacy supplier sync integration action", role_template_name = "IntegrationAdmin" },
  ]
}

# The destination module isn't instantiated here yet - see this folder's
# README's "not yet applied" section for why (legacy-erp-gateway isn't
# reachable from BTP yet, applying it now would create a destination that
# can never resolve).
