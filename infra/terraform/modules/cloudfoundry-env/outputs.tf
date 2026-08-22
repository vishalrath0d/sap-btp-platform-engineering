output "id" {
  value = length(local.cloudfoundry_instances) > 0 ? local.cloudfoundry_instances[0].id : null
}

output "dashboard_url" {
  value = length(local.cloudfoundry_instances) > 0 ? local.cloudfoundry_instances[0].dashboard_url : null
}

output "org_name" {
  value = length(local.cloudfoundry_instances) > 0 ? local.cloudfoundry_instances[0].name : null
}
