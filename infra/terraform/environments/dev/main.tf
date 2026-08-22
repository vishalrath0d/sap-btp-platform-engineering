module "subaccount" {
  source    = "../../modules/subaccount"
  subdomain = var.subaccount_subdomain
}

module "entitlements" {
  source        = "../../modules/entitlements"
  subaccount_id = module.subaccount.id

  entitlements = [
    { service_name = "cloudfoundry", plan_name = "standard" },
    { service_name = "kymaruntime", plan_name = "trial" },
    { service_name = "hana-cloud-trial", plan_name = "hana-cloud-trial" },
  ]
}

module "cloudfoundry_environment" {
  source          = "../../modules/cloudfoundry-environment"
  subaccount_id   = module.subaccount.id
  org_name        = "procureiq-dev"
  landscape_label = "cf-${var.region}"

  depends_on = [module.entitlements]
}

module "kyma_environment" {
  source         = "../../modules/kyma-environment"
  subaccount_id  = module.subaccount.id
  name           = "procureiq-kyma-dev"
  plan_name      = "trial"
  administrators = var.kyma_administrators

  depends_on = [module.entitlements]
}

module "xsuaa" {
  source                = "../../modules/xsuaa"
  subaccount_id         = module.subaccount.id
  name_prefix           = "procurement-core-dev"
  xs_security_json_path = "${path.module}/../../../../services/procurement-core/xs-security.json"
}

module "role_collections" {
  source          = "../../modules/role-collections"
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
