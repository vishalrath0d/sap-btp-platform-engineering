resource "btp_subaccount_environment_instance" "this" {
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
