# The trial provides exactly one subaccount, already created during signup.
# Terraform looks it up (data source) rather than creating it (resource) -
# a trial global account is entitled to a single subaccount, so a
# `resource "btp_subaccount"` block here would fail on apply. Everything
# else in this module references data.btp_subaccount.trial.id (a GUID),
# never the subdomain - the subdomain is a human-friendly lookup key, the
# ID is the stable reference every other BTP resource actually wants.
data "btp_subaccount" "trial" {
  subdomain = var.subaccount_subdomain
}

output "subaccount_id" {
  value       = data.btp_subaccount.trial.id
  description = "The subaccount's GUID."
}

output "subaccount_region" {
  value       = data.btp_subaccount.trial.region
  description = "Confirms the region Terraform is actually resolving against - compare this to var.region after the first `terraform plan` to catch a mismatch early."
}
