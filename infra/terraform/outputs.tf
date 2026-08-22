output "subaccount_id" {
  value = module.subaccount.id
}

output "subaccount_region" {
  value = module.subaccount.region
}

output "cloudfoundry_org_id" {
  value = module.cloudfoundry_env.id
}

output "kyma_dashboard_url" {
  value = module.kyma_env.dashboard_url
}

output "xsuaa_credentials" {
  value       = module.xsuaa.credentials
  description = "Contains the real xsappname role_collections needs for its second apply pass."
  sensitive   = true
}
