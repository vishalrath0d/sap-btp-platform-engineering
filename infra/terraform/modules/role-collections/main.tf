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
    # var.xsuaa_xsappname == "" gates ALL creation, not just this one
    # rc - a genuinely first-ever apply, before procurement-core has
    # ever been deployed for real, has no real xsappname to reference
    # yet. Skipping cleanly here (rather than creating role collections
    # with an empty role_template_app_id, which the real API would
    # likely reject or silently misassociate) is the honest version of
    # the same self-healing-on-second-apply property this module
    # already had for the XSUAA auto-creation race below - re-running
    # apply after a real deploy (with xsuaa_xsappname set) picks these
    # up correctly.
    if !contains(local.existing_names, rc.name) && var.xsuaa_xsappname != ""
  }
}

# Real two-phase apply now (see infra/terraform/variables.tf's
# xsuaa_xsappname description for why modules/xsuaa's same-xsappname
# duplicate approach was reverted) - var.xsuaa_xsappname is a plain
# input, known at plan time once set, not a same-apply resource
# attribute dependency the way it briefly was.
#
# Known residual edge case, honestly stated rather than hidden (same
# class of thing infra/terraform/README.md already documents for CF/Kyma
# entitlements): on a genuinely fresh subaccount where XSUAA's instance
# AND these role collections are BOTH being created for the very first
# time in the SAME apply, this data source's plan-time snapshot is taken
# before XSUAA's auto-creation has happened - so the very first apply
# with xsuaa_xsappname set might still see them as "missing," attempt to
# create them, and hit the same creationType conflict once. Re-running
# `terraform apply` a second time resolves it correctly (XSUAA and its
# auto-created role collections already exist by then, this module's
# lookup correctly adopts them) - a real, low-severity, self-healing
# edge case on a genuinely fresh account, not a bug that recurs on every
# apply.
resource "btp_subaccount_role_collection" "this" {
  for_each = local.to_create

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

# Assigns var.assign_to_user to all 3 role collections - what actually
# makes the deployed, XSUAA-protected procurement-core API testable by a
# real user (see docs/operations/networking-and-request-flow.md §3 and
# the root README's "Live on BTP" section for why this was previously a
# gap: no real user had the role collections, so no real token would
# have carried the Requester/Approver scopes the CDS model's @requires
# annotations check). A genuinely BTP-scoped concept
# (btp_subaccount_role_collection_assignment - subaccount-level,
# unrelated to the CF-space-scoping issues modules/hana-cloud hit), so
# Terraform is the correct tool here, unlike that case.
#
# Gated the same way as resource "this" above - skips cleanly on a
# genuinely first-ever apply (var.xsuaa_xsappname == "") or if no user
# was supplied (var.assign_to_user == "", the default) rather than
# erroring against role collections that don't exist yet.
resource "btp_subaccount_role_collection_assignment" "this" {
  for_each = (var.xsuaa_xsappname != "" && var.assign_to_user != "") ? toset([
    for rc in var.role_collections : rc.name
  ]) : []

  subaccount_id        = var.subaccount_id
  role_collection_name = each.value
  user_name            = var.assign_to_user
}
