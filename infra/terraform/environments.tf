# Provisions the two runtimes procurement-core and spend-anomaly-detector
# actually target (see PROJECT_CHARTER.md) - Cloud Foundry for the CAP app,
# Kyma for the eventing-side microservice. Both depend on the entitlements
# in entitlements.tf existing first; Terraform's dependency graph handles
# the ordering automatically since these resources reference
# btp_subaccount_entitlement's subaccount_id via the shared data source, but
# an explicit `depends_on` is added anyway since the entitlement->environment
# ordering isn't otherwise visible from a resource-argument reference alone.

resource "btp_subaccount_environment_instance" "cloudfoundry" {
  subaccount_id    = data.btp_subaccount.trial.id
  name             = "procureiq-${var.environment}"
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "standard"
  landscape_label  = var.region

  # CF org creation parameters - org_name is what `cf orgs` will show.
  parameters = jsonencode({
    instance_name = "procureiq-${var.environment}"
    org_name      = "procureiq-${var.environment}"
  })

  depends_on = [btp_subaccount_entitlement.cloudfoundry]
}

resource "btp_subaccount_environment_instance" "kyma" {
  subaccount_id    = data.btp_subaccount.trial.id
  name             = "procureiq-kyma-${var.environment}"
  environment_type = "kyma"
  service_name     = "kymaruntime"
  plan_name        = "trial"

  # Trial Kyma clusters are provisioned with SAP-managed defaults; an empty
  # object is the documented minimum. Provisioning genuinely takes
  # 15-20 minutes - `terraform apply` will sit on this resource for a while,
  # which is expected, not a hang.
  parameters = jsonencode({})

  depends_on = [btp_subaccount_entitlement.kyma]
}

output "cloudfoundry_org_id" {
  value       = btp_subaccount_environment_instance.cloudfoundry.id
  description = "Once created, `cf login` targets this org via the API endpoint in the resource's dashboard_url / labels output (check `terraform show` after apply)."
}

output "kyma_dashboard_url" {
  value       = btp_subaccount_environment_instance.kyma.dashboard_url
  description = "The Kyma cluster's dashboard/kubeconfig retrieval URL."
}
