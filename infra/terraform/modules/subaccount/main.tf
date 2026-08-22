# A data source, not a resource: a trial global account is entitled to
# exactly one subaccount, already created at signup - declaring it as a
# resource would fail on apply. A paid landscape's qa/prod environments
# (see ../../environments/qa, ../../environments/prod) would use this same
# module against subaccounts created by a different, account-provisioning
# module not included here (out of scope until a paid landscape exists -
# see environments/qa/main.tf's header comment).
data "btp_subaccount" "this" {
  subdomain = var.subdomain
}
