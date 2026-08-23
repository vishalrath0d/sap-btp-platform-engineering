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
    # The two below are new - added to close the resume/portfolio gap on
    # supplier-master-abap and services/integration-flow (see
    # PROJECT_CHARTER.md's "ABAP Environment and Integration Suite" note).
    # service_name/plan_name here are sourced from SAP's own cockpit
    # documentation (the cockpit lists "ABAP Environment" / "Integration
    # Suite" with a "trial" plan for each), not verified against the live
    # entitlement catalog the way cloudfoundry/kymaruntime/hana-cloud-trial
    # above were - this project doesn't have live btp CLI credentials in
    # this environment to check the catalog directly. Flagged here exactly
    # the way this file's own history already handles this class of risk:
    # written from the best-sourced value, corrected from whatever the
    # next real `terraform plan` run actually reports (that loop has
    # already caught and fixed several wrong assumptions in this project -
    # see infra/terraform/README.md's "Update - verified live" section).
    { service_name = "abap", plan_name = "trial" },
    { service_name = "integration-suite", plan_name = "trial" },
  ]
}

module "cloudfoundry_env" {
  # Adaptive: adopts the existing CF org if one's already provisioned
  # (true for this trial - confirmed `cf delete-org` fails, "not
  # authorized"), creates one with these values if none exists (true for
  # a fresh/real subaccount). See modules/cloudfoundry-env/main.tf.
  #
  # Deliberately NO `depends_on = [module.entitlements]` here anymore - a
  # real Terraform constraint, not an oversight: this module's `count` is
  # driven by a data-source lookup, and `depends_on` on a module forces
  # everything inside it (including data sources that would otherwise
  # resolve during plan) to defer to apply-time - which then makes `count`
  # un-computable during plan ("depends on resource attributes that cannot
  # be determined until apply"), a real error hit on this exact PR.
  # Practical implication, not hidden: on a genuinely fresh subaccount
  # with zero entitlements yet, the very first `apply` might need to run
  # twice (once to grant entitlements, once more to create the
  # environments) - the same kind of two-phase reality
  # modules/role-collections already documents for XSUAA, not a new problem.
  source          = "./modules/cloudfoundry-env"
  subaccount_id   = module.subaccount.id
  org_name        = "procureiq-${var.environment}"
  landscape_label = "cf-${var.region}"
}

module "kyma_env" {
  # See cloudfoundry_env's comment above - same reasoning, same fix.
  source         = "./modules/kyma-env"
  subaccount_id  = module.subaccount.id
  name           = "procureiq-kyma-${var.environment}"
  plan_name      = "trial"
  administrators = var.kyma_administrators
}

module "xsuaa" {
  source                = "./modules/xsuaa"
  subaccount_id         = module.subaccount.id
  name_prefix           = "procurement-core-${var.environment}"
  xs_security_json_path = "${path.module}/../../services/procurement-core/xs-security.json"
}

module "role_collections" {
  # xsuaa_credentials_json creates an implicit dependency on module.xsuaa
  # automatically - no explicit depends_on needed, and (unlike the old
  # xsuaa_xsappname variable this replaced) no manual two-phase apply
  # either. See modules/role-collections/main.tf.
  source                 = "./modules/role-collections"
  subaccount_id          = module.subaccount.id
  xsuaa_credentials_json = module.xsuaa.credentials

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
