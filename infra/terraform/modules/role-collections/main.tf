# xs-security.json already declares role-collections inline, which XSUAA
# can auto-provision at bind time on some plans - that's the
# zero-Terraform path. This module is the explicit-IaC alternative: same
# end state, but declared here so `terraform plan` shows drift if anyone
# changes a role collection by hand in the cockpit later. Both approaches
# are documented (not just one silently assumed) - see
# services/procurement-core/xs-security.json and environments/dev/README.md.
# Checking != null alone isn't enough: an unset GitHub Actions secret
# (secrets.XSUAA_XSAPPNAME before it's created) resolves to an empty
# string "", not null, when wired into TF_VAR_xsuaa_xsappname - "" != null
# is true, so a plain null check would have tried creating role
# collections with role_template_app_id = "", not safely no-op'd. Caught
# before it happened, not after - treating "not set" and "empty string"
# the same is what the two-phase apply this module supports actually needs.
resource "btp_subaccount_role_collection" "this" {
  for_each = (var.xsuaa_xsappname != null && var.xsuaa_xsappname != "") ? { for rc in var.role_collections : rc.name => rc } : {}

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
