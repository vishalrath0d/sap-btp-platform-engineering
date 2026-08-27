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
  # Gated to 0 (2026-08-27; was `var.kyma_enabled ? 1 : 0` while the
  # trial request was pending) - real capability boundary found live,
  # same category as modules/hana_cloud and modules/xsuaa below, not a
  # bug in this module's own code. SAP approved the trial Kyma request
  # and the cluster is real and fully working (confirmed directly via
  # kubectl against it: 1 node Ready, BTP Operator Ready, all expected
  # CRDs present) - but a temporary debug output on this exact module
  # (see git history around 2026-08-27) proved `data.btp_subaccount_
  # environment_instances` genuinely does not return it: the API lists
  # exactly one instance for this subaccount, the pre-existing Cloud
  # Foundry one, even with the Kyma cluster live and in daily use. SAP's
  # trial-Kyma-approval flow provisions the cluster through its own
  # dedicated broker (see the kubeconfig download URL from the approval
  # email: kyma-env-broker.cp.kyma.cloud.sap) rather than through the
  # standard self-service environment-instance path this data source
  # queries - so this module's adopt-lookup has nothing it CAN adopt,
  # and (per the two already-documented CREATION_FAILED results from
  # session 10, before approval) attempting to create is known to fail
  # too. There is genuinely nothing for Terraform to manage here on this
  # trial: the cluster is used directly via its kubeconfig (a GitHub
  # Actions secret, KYMA_KUBECONFIG - see kyma-deploy.yml) instead.
  # var.kyma_enabled stays true and still means something real - it's
  # the landscape-level flag other tooling/docs read to know Kyma is
  # part of this environment now - it just no longer drives this
  # specific resource's count, since driving it was never going to work
  # on this trial regardless of its value. Module kept whole, not
  # deleted: it's correct Terraform for a subaccount where this same
  # data source genuinely does list Kyma (a non-trial/paid account, or a
  # trial where Kyma was self-service-enabled rather than support-
  # approved) - just not this trial's actual shape.
  count = 0

  source         = "./modules/kyma-env"
  subaccount_id  = module.subaccount.id
  name           = "procureiq-kyma-${var.environment}"
  plan_name      = "trial"
  administrators = var.kyma_administrators
}

module "hana_cloud" {
  # Gated to 0 (destroys the one this module previously created) - real
  # capability boundary found live, not a bug in this module's own code:
  # `btp_subaccount_service_instance` creates a Service-Manager/
  # subaccount-scoped instance, confirmed via `cf curl /v3/service_
  # instances?names=...` returning zero results for it in the dev CF
  # space, and via the BTP cockpit's own Space > Service Instances view
  # (screenshot evidence) never listing it - the "hana"/"hdi-shared"
  # broker needs a database visible to the CF *space* specifically ("no
  # database available... in space 'dev'"), which this resource type
  # cannot produce. Exhaustively checked the real provider schema
  # (v1.26.0, every resource_schemas/data_source_schemas key) for a
  # platform/CF-space-scoping mechanism - none exists; `platform_id` on
  # this resource is computed-only, not settable. CF-space-scoped
  # resources are the separate `cloudfoundry/cloudfoundry` provider's
  # domain, not `SAP/btp`'s - not adding a second provider for one
  # resource. The database is instead created directly via
  # `cf create-service` in cf-deploy.yml's procurement-core job (real
  # CF-space scope, matches how a plain `cf create-service` instance
  # showed up correctly scoped in the same cockpit view). Module kept
  # whole, not deleted, same convention as modules/kyma-env - it's
  # correct Terraform for a subaccount-level HANA Cloud instance, just
  # not the shape this specific broker needs.
  count = 0

  source        = "./modules/hana-cloud"
  subaccount_id = module.subaccount.id
  name_prefix   = "procureiq-${var.environment}"
}

module "xsuaa" {
  # Gated to 0 (destroys the one this module previously created) - real
  # conflict found live, not a bug in this module's own code: procurement-
  # core's MTA declares its OWN XSUAA "application" plan resource
  # (services/procurement-core/mta.yaml), using the exact same xs-
  # security.json and therefore the exact same xsappname
  # ("procurement-core"). A second, Terraform-managed instance under that
  # same xsappname genuinely conflicts at the broker level - every MTA
  # deploy attempt failed creating procurement-core-xsuaa with a broker-
  # side NPE (ScaleOutLandscapeImpl.getEndpoints(), scaleOutLandscape
  # null) for as long as this module's instance existed alongside it, and
  # that error stopped the moment the duplicate was destroyed (real,
  # reproduced live). See infra/terraform/variables.tf's xsuaa_xsappname
  # description for how modules/role-collections now learns the real
  # xsappname instead - from the MTA's own instance, not a duplicate.
  # Module kept whole, not deleted, same convention as modules/kyma-env/
  # modules/hana-cloud - it's correct Terraform for a subaccount-level
  # XSUAA instance, just not needed alongside an MTA that creates its own.
  count = 0

  source                = "./modules/xsuaa"
  subaccount_id         = module.subaccount.id
  name_prefix           = "procurement-core-${var.environment}"
  xs_security_json_path = "${path.module}/../../services/procurement-core/xs-security.json"
}

module "role_collections" {
  # xsuaa_xsappname is a plain, manually-supplied value (real two-phase
  # apply: deploy procurement-core first, fetch its real xsuaa instance's
  # xsappname, THEN apply terraform with it set) - see infra/terraform/
  # variables.tf and modules/xsuaa's own comment above for why the
  # same-apply, credentials-JSON-from-a-duplicate-instance approach this
  # replaced was reverted.
  source          = "./modules/role-collections"
  subaccount_id   = module.subaccount.id
  xsuaa_xsappname = var.xsuaa_xsappname
  # Assigns the real, applying BTP user (var.btp_username) to all 3 role
  # collections - what makes the deployed procurement-core API testable
  # end-to-end by a real user, not just adopted-and-unused role
  # collections. See modules/role-collections/main.tf's own comment.
  assign_to_user = var.btp_username

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
