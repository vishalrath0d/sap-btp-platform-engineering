# NOTE - two-phase apply: var.xsuaa_xsappname isn't knowable until
# security.tf's XSUAA binding has actually been created once (see that
# file's comment). Leave this file's resources commented out (or the
# variable unset) on the *first* apply; after reading the real xsappname
# from `terraform output -json xsuaa_credentials`, set it and apply again.
#
# xs-security.json (services/procurement-core/xs-security.json) already
# declares role-collections inline, which XSUAA can auto-provision at bind
# time on some plans - that's the zero-Terraform path. These resources are
# the explicit-IaC alternative: same end state, but declared here instead
# of implicitly by the security descriptor, so `terraform plan` shows drift
# if anyone changes a role collection by hand in the cockpit later.

variable "xsuaa_xsappname" {
  description = "The real XSUAA xsappname, e.g. procurement-core!t12345 - only known after security.tf's service binding is created once. Leave null until then."
  type        = string
  default     = null
}

locals {
  role_collections_enabled = var.xsuaa_xsappname != null
}

resource "btp_subaccount_role_collection" "requester" {
  count         = local.role_collections_enabled ? 1 : 0
  subaccount_id = data.btp_subaccount.trial.id
  name          = "ProcureIQ Requester"
  description   = "Business users who raise Purchase Requisitions"

  roles = [
    {
      name                 = "Requester"
      role_template_app_id = var.xsuaa_xsappname
      role_template_name   = "Requester"
    }
  ]
}

resource "btp_subaccount_role_collection" "approver" {
  count         = local.role_collections_enabled ? 1 : 0
  subaccount_id = data.btp_subaccount.trial.id
  name          = "ProcureIQ Approver"
  description   = "Approves submitted Purchase Requisitions"

  roles = [
    {
      name                 = "Approver"
      role_template_app_id = var.xsuaa_xsappname
      role_template_name   = "Approver"
    }
  ]
}

resource "btp_subaccount_role_collection" "integration_admin" {
  count         = local.role_collections_enabled ? 1 : 0
  subaccount_id = data.btp_subaccount.trial.id
  name          = "ProcureIQ Integration Admin"
  description   = "Runs the legacy supplier sync integration action"

  roles = [
    {
      name                 = "IntegrationAdmin"
      role_template_app_id = var.xsuaa_xsappname
      role_template_name   = "IntegrationAdmin"
    }
  ]
}
