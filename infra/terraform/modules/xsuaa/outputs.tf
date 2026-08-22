output "service_instance_id" {
  value = btp_subaccount_service_instance.xsuaa.id
}

output "credentials" {
  value       = btp_subaccount_service_binding.xsuaa.credentials
  description = "Contains the real xsappname (assigned by XSUAA at bind time, e.g. 'procurement-core!t12345') that modules/role-collections needs - genuinely two-phase, see environments/dev/README.md."
  sensitive   = true
}
