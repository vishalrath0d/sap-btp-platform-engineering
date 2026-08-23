# xs-security.json already declares role-collections inline, which XSUAA
# can auto-provision at bind time on some plans - that's the
# zero-Terraform path. This module is the explicit-IaC alternative: same
# end state, but declared here so `terraform plan` shows drift if anyone
# changes a role collection by hand in the cockpit later.
#
# Single apply, not two-phase: for_each below is FIXED (always the 3
# entries in var.role_collections) - only role_template_app_id, a
# resource ATTRIBUTE, depends on modules/xsuaa's credentials, which are
# only known after that binding is actually created. Terraform sequences
# this correctly within one `terraform apply` (create the XSUAA binding,
# then create these role collections referencing its output) because
# attributes are allowed to depend on apply-time values; only for_each/
# count are not. An earlier version of this module got this backwards -
# gating for_each itself on the unknown value - which is what actually
# forced two separate `terraform apply` runs. Not a Terraform limitation,
# a design mistake, now fixed.
resource "btp_subaccount_role_collection" "this" {
  for_each = { for rc in var.role_collections : rc.name => rc }

  subaccount_id = var.subaccount_id
  name          = each.value.name
  description   = each.value.description

  roles = [
    {
      name                 = each.value.role_template_name
      role_template_app_id = local.xsuaa_xsappname
      role_template_name   = each.value.role_template_name
    }
  ]
}

locals {
  xsuaa_xsappname = jsondecode(var.xsuaa_credentials_json).xsappname
}
