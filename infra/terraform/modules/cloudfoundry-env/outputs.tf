output "id" {
  value = local.cloudfoundry_id
}

output "dashboard_url" {
  value = local.cloudfoundry_dashboard_url
}

output "org_name" {
  value = local.cloudfoundry_org_name
}

output "was_pre_existing" {
  value       = local.cloudfoundry_exists
  description = "true if this module adopted an already-provisioned CF environment (e.g. a trial), false if it created a new one - useful to see in `terraform output` which branch actually ran."
}
