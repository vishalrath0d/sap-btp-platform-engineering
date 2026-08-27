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

# Temporary diagnostic output (to be deleted after use) - see
# modules/kyma-env/outputs.tf's own comment.
output "debug_kyma_all_instances" {
  value = try(module.kyma_env[0].debug_all_environment_instances, null)
}
output "debug_kyma_exists" {
  value = try(module.kyma_env[0].debug_kyma_exists, null)
}

# No xsuaa_credentials output anymore - module.xsuaa is gated to count=0
# (see main.tf's comment: a same-xsappname duplicate of procurement-
# core's own MTA-created XSUAA instance genuinely conflicts at the
# broker level). role_collections now gets the real xsappname from
# var.xsuaa_xsappname, fetched live from that MTA-created instance via
# cf create-service-key (see terraform-apply.yml), not from this module.
