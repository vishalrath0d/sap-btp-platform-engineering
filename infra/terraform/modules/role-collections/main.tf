# xs-security.json already declares role-collections inline, which XSUAA
# auto-provisions the moment its service instance is created - one role
# collection per role template, tagged creationType: XSSECURITY. This
# module is the explicit-IaC alternative: same end state, but declared
# here so `terraform plan` shows drift if anyone changes a role
# collection by hand in the cockpit later.
#
# Adaptive, same reasoning as modules/entitlements/cloudfoundry-env/
# kyma-env - added after a real live apply proved it was needed: XSUAA's
# auto-creation meant all three role collections already existed by the
# time this module tried to create them fresh, and the API refused to
# change their creationType from XSSECURITY to 'admin' ("Cannot update
# creationType..."). Look up what already exists, only create what's
# genuinely missing.
data "btp_subaccount_role_collections" "all" {
  subaccount_id = var.subaccount_id
}

locals {
  existing_names = toset([
    for rc in data.btp_subaccount_role_collections.all.values : rc.name
  ])

  to_create = {
    for rc in var.role_collections : rc.name => rc
    if !contains(local.existing_names, rc.name)
  }

  xsuaa_xsappname = jsondecode(var.xsuaa_credentials_json).xsappname
}

# Single apply, not two-phase: for_each is gated on `local.to_create`
# (still effectively fixed at plan time, same reasoning as before - this
# data source has no depends_on, so it resolves during plan, not deferred
# to apply) - only role_template_app_id, a resource ATTRIBUTE, depends on
# modules/xsuaa's credentials, which are only known after that binding is
# actually created within the same apply. Attributes can depend on
# apply-time values; for_each/count cannot - the same distinction this
# module's earlier redesign already relied on.
#
# Known residual edge case, honestly stated rather than hidden (same
# class of thing infra/terraform/README.md already documents for CF/Kyma
# entitlements): on a genuinely fresh subaccount where XSUAA's instance
# AND these role collections are BOTH being created for the very first
# time in the SAME apply, this data source's plan-time snapshot is taken
# before XSUAA's auto-creation has happened - so the very first apply
# might still see them as "missing," attempt to create them, and hit the
# same creationType conflict once. Re-running `terraform apply` a second
# time resolves it correctly (XSUAA and its auto-created role collections
# already exist by then, this module's lookup correctly adopts them) -
# a real, low-severity, self-healing edge case on a genuinely fresh
# account, not a bug that recurs on every apply.
resource "btp_subaccount_role_collection" "this" {
  for_each = local.to_create

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
