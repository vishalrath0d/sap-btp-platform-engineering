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
    # amount = 1 is real and required, not a guess: a live apply failed
    # here with "A quota was not set in the amount parameter" -
    # kymaruntime's entitlement category is SERVICE (numeric quota
    # required), unlike ELASTIC_SERVICE entitlements which don't take one
    # at all. 1 is the standard trial Kyma quota.
    { service_name = "kymaruntime", plan_name = "trial", amount = 1 },
    { service_name = "hana-cloud-trial", plan_name = "hana-cloud-trial" },
    # cloudfoundry/standard and hana-cloud-trial/hana-cloud-trial above
    # both failed live apply too - "the global account is not entitled to
    # this service plan" - a real, live-verified correction to this
    # file's own earlier "confirmed correct" claim (terraform plan never
    # validates against the live catalog, only apply does). Left as-is
    # rather than guessing a replacement name: modules/entitlements is now
    # adaptive (looks up what's already entitled, only creates what's
    # missing) - since both are near-certainly already pre-granted on this
    # trial by default, the adaptive lookup should just adopt them and
    # skip trying to (re-)create them, regardless of what this file's
    # guessed plan_name says. If the next live apply proves that wrong,
    # fix here with the real value from `btp list accounts/entitlement`.
    #
    # abap/integration-suite below are genuinely NOT pre-granted (a
    # different live error: same message, but these two are real "you
    # don't have this yet" rejections, not "already exists" ones) - still
    # unverified against the live catalog, corrected once the real plan
    # names are confirmed via the BTP cockpit's Entitlements -> Add
    # Service Plans catalog (no CLI equivalent for not-yet-assigned plans
    # was found).
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
