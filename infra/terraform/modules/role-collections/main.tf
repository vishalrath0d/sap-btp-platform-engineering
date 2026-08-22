# xs-security.json already declares role-collections inline, which XSUAA
# can auto-provision at bind time on some plans - that's the
# zero-Terraform path. This module is the explicit-IaC alternative: same
# end state, but declared here so `terraform plan` shows drift if anyone
# changes a role collection by hand in the cockpit later. Both approaches
# are documented (not just one silently assumed) - see
# services/procurement-core/xs-security.json and environments/dev/README.md.
resource "btp_subaccount_role_collection" "this" {
  for_each = var.xsuaa_xsappname != null ? { for rc in var.role_collections : rc.name => rc } : {}

  subaccount_id = var.subaccount_id
  name          = each.value.name
  description   = each.value.description

  roles = [
    {
      name                 = each.value.role_template_name
      role_template_app_id = var.xsuaa_xsappname
      role_template_name   = each.value.role_template_name
    }
  ]
}
