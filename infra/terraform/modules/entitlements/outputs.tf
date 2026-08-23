output "entitlement_ids" {
  value       = { for k, e in btp_subaccount_entitlement.this : k => e.id }
  description = "Keyed by 'service_name/plan_name' - only the entitlements this apply actually created (not the ones already granted and adopted). Useful for depends_on references from environment/xsuaa modules."
}

output "adopted_entitlements" {
  value       = local.existing_keys
  description = "'service_name/plan_name' keys that were already entitled before this apply and were left alone, not recreated."
}
