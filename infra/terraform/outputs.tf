output "subaccount_id" {
  value = module.subaccount.id
}

output "subaccount_region" {
  value = module.subaccount.region
}

output "cloudfoundry_org_id" {
  value = module.cloudfoundry_env.id
}

output "cloudfoundry_org_name" {
  value       = module.cloudfoundry_env.org_name
  description = "The real CF org name - read this at deploy time (`terraform output -raw cloudfoundry_org_name`), never hardcode it. On a trial this is an SAP-assigned name (confirmed live: '4cbf0c12trial', not the 'procureiq-<env>' this module would name a freshly-created org) - the adaptive lookup in modules/cloudfoundry-env adopts whatever already exists rather than creating a second org trial accounts don't allow, so the module's own var.org_name is never actually applied there. On a real paid account with no pre-existing org, this returns the created 'procureiq-<env>' name instead - same output works correctly either way, which is the point of reading it instead of assuming it."
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
