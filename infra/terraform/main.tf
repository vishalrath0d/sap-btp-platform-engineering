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

  # Every value below is real, from `btp list accounts/entitlement
  # --subaccount <id>`'s actual output (run live, not guessed) plus the
  # BTP cockpit's Entitlements -> Add Service Plans catalog for the two
  # that don't show up in an already-granted listing. This replaces a
  # prior version whose names were wrong in a specific, now-understood
  # way: not "not entitled at all," but genuinely different real names
  # for things already granted on this trial (cloudfoundry/standard vs.
  # the real cloudfoundry/trial; hana-cloud-trial/hana-cloud-trial, which
  # doesn't exist as an entitlement at all, vs. the real hana/hdi-shared;
  # abap/trial vs. the real abap-trial/shared; integration-suite/trial
  # vs. the real integrationsuite-trial/trial). All five are confirmed
  # already granted (quota >= 1 each) - modules/entitlements' adaptive
  # lookup should now match and adopt every one of them, not create any.
  entitlements = [
    { service_name = "cloudfoundry", plan_name = "trial" },
    # amount = 1 is real and required, not a guess: a live apply failed
    # here with "A quota was not set in the amount parameter" -
    # kymaruntime's entitlement category is SERVICE (numeric quota
    # required), unlike ELASTIC_SERVICE entitlements which don't take one
    # at all. 1 matches the real granted quota.
    { service_name = "kymaruntime", plan_name = "trial", amount = 1 },
    # hana/hdi-shared's real granted quota is 10, not 1 - a real, non-1
    # quota is itself a strong signal this is also a SERVICE-category
    # entitlement needing an explicit amount, same reasoning as
    # kymaruntime above. Matters only if this ever needs to actually
    # create the entitlement (a real/paid account where it isn't
    # pre-granted) - on this trial the adaptive lookup adopts the
    # already-granted one and this value is never used to create anything.
    { service_name = "hana", plan_name = "hdi-shared", amount = 10 },
    { service_name = "abap-trial", plan_name = "shared" },
    { service_name = "integrationsuite-trial", plan_name = "trial" },
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
  # Gated on var.kyma_enabled (default false) - kept whole, not deleted
  # or commented out: this trial account genuinely has no self-service
  # Kyma provisioning (confirmed twice over, see modules/kyma-env/
  # main.tf's own comment and docs/next/next.md) - a request has been
  # sent to SAP and is pending approval (up to a month). Every apply
  # would otherwise fail on this one resource for a reason no retry
  # fixes, blocking the whole apply over one thing that isn't ready yet.
  # `count`, not the module going away, so flipping kyma_enabled back to
  # true later (in environments/<env>/terraform.tfvars) needs no further
  # code change - the module itself was never touched. Module-level
  # count is real, standard Terraform (1.x+), same mechanism this
  # project's other adaptive modules already use internally.
  count = var.kyma_enabled ? 1 : 0

  source         = "./modules/kyma-env"
  subaccount_id  = module.subaccount.id
  name           = "procureiq-kyma-${var.environment}"
  plan_name      = "trial"
  administrators = var.kyma_administrators
}

module "hana_cloud" {
  # Real gap found only once procurement-core's MTA deploy actually ran:
  # "hana"/"hdi-shared" (see modules/entitlements) provisions HDI
  # containers on an existing database, it doesn't create one - this
  # module creates that database. See modules/hana-cloud/main.tf's
  # header for the full real-error trail.
  source        = "./modules/hana-cloud"
  subaccount_id = module.subaccount.id
  name_prefix   = "procureiq-${var.environment}"
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
