output "entitlement_ids" {
  value       = { for k, e in btp_subaccount_entitlement.this : k => e.id }
  description = "Keyed by 'service_name/plan_name' - useful for depends_on references from environment/xsuaa modules."
}
