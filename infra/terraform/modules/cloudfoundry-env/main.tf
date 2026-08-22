# Back to a resource (creates a new CF environment), not the data-source
# lookup this file held briefly - reverted per explicit instruction: the
# manually-created org (from earlier interactive BTP setup) is being
# deleted so Terraform owns creation end to end, matching this project's
# actual IaC goal ("destroy the trial, terraform apply, get the same
# landscape back"). A data-source lookup would have made sense to *adopt*
# an org you wanted to keep manually; that's not the goal here.
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
