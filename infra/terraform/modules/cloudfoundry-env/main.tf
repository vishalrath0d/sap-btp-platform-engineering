# Data-source lookup (active) - confirmed via `cf delete-org` actually
# failing ("You are not authorized to perform the requested action"):
# trial's default CF org genuinely cannot be deleted, so Terraform must
# adopt the existing one rather than create a new one.
data "btp_subaccount_environment_instances" "all" {
  subaccount_id = var.subaccount_id
}

locals {
  cloudfoundry_instances = [
    for env in data.btp_subaccount_environment_instances.all.values : env
    if env.environment_type == "cloudfoundry"
  ]
}

# --- Kept commented, not deleted, per explicit instruction ---
# The creation path below is real and correct for a landscape where CF
# genuinely doesn't exist yet (a fresh non-trial subaccount, or - maybe -
# qa/prod once those exist for real). Uncomment and swap main.tf's module
# call back to these variables if that's ever the case; until then the
# data source above is what's actually used.
#
# resource "btp_subaccount_environment_instance" "this" {
#   subaccount_id    = var.subaccount_id
#   name             = var.org_name
#   environment_type = "cloudfoundry"
#   service_name     = "cloudfoundry"
#   plan_name        = "standard"
#   landscape_label  = var.landscape_label
#
#   parameters = jsonencode({
#     instance_name = var.org_name
#     org_name      = var.org_name
#   })
# }
