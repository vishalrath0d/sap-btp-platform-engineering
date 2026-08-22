# Provisions the XSUAA service instance procurement-core will bind to,
# using the same xs-security.json that also ships with the app itself
# (services/procurement-core/xs-security.json) - one source of truth for
# the role/scope model, referenced from both the MTA deployment descriptor
# and this Terraform module, not duplicated and risking drift between them.

resource "btp_subaccount_service_instance" "xsuaa" {
  subaccount_id         = data.btp_subaccount.trial.id
  name                  = "procurement-core-xsuaa-${var.environment}"
  service_offering_name = "xsuaa"
  serviceplan_name      = "application"
  parameters            = file("${path.module}/../../services/procurement-core/xs-security.json")
}

resource "btp_subaccount_service_binding" "xsuaa" {
  subaccount_id       = data.btp_subaccount.trial.id
  name                = "procurement-core-xsuaa-binding-${var.environment}"
  service_instance_id = btp_subaccount_service_instance.xsuaa.id
}

# The real xsappname (e.g. "procurement-core!t12345") only exists after the
# binding above is actually created - it's assigned by XSUAA at bind time,
# not knowable in advance. That's a genuine two-phase-apply reality with
# XSUAA + Terraform, not an oversight here: apply once to create the
# instance+binding, read the xsappname out of the binding's credentials
# (`terraform output -json xsuaa_credentials` or the cockpit), then apply
# again for role_collections.tf to actually wire up (it needs that value).
output "xsuaa_credentials" {
  value       = btp_subaccount_service_binding.xsuaa.credentials
  description = "Contains the real xsappname role_collections.tf needs. Sensitive - do not log or commit its rendered value."
  sensitive   = true
}
