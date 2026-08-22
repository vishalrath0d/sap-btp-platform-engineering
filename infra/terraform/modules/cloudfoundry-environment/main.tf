resource "btp_subaccount_environment_instance" "this" {
  subaccount_id    = var.subaccount_id
  name             = var.org_name
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "standard"
  landscape_label  = var.landscape_label

  parameters = jsonencode({
    instance_name = var.org_name
    org_name      = var.org_name
  })
}
