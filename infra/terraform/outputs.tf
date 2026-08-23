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
  value       = try(module.kyma_env[0].dashboard_url, null)
  description = "null while kyma_enabled = false (module.kyma_env isn't instantiated at all) - see main.tf's comment on that module call."
}

output "xsuaa_credentials" {
  value       = module.xsuaa.credentials
  description = "Contains the real xsappname role_collections needs for its second apply pass."
  sensitive   = true
}
