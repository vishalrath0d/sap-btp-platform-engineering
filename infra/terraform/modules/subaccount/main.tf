# A data source, not a resource: a trial global account is entitled to
# exactly one subaccount, already created at signup - declaring it as a
# resource would fail on apply. A paid landscape's qa/prod environments
# (see ../../environments/qa, ../../environments/prod) would use this same
# module against subaccounts created by a different, account-provisioning
# module not included here (out of scope until a paid landscape exists -
# see environments/qa/main.tf's header comment).
data "btp_subaccount" "this" {
  subdomain = var.subdomain
  region    = var.region
  # A real bug from the first live `terraform plan`, not visible to
  # `terraform validate`: the SAP/btp provider requires `region` whenever
  # `subdomain` is set on this data source - the schema marks both as
  # individually optional, but there's a runtime attribute-combination
  # rule the schema dump alone doesn't surface. Only caught by an actual
  # plan against the real API.
}
