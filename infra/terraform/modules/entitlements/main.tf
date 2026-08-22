# for_each-over-a-list pattern confirmed against a real applied example in
# SAP-samples/btp-terraform-samples (released/usecases/dev_test_prod_setup) -
# not invented for this project.
resource "btp_subaccount_entitlement" "this" {
  for_each = { for e in var.entitlements : "${e.service_name}/${e.plan_name}" => e }

  subaccount_id = var.subaccount_id
  service_name  = each.value.service_name
  plan_name     = each.value.plan_name
  amount        = each.value.amount
}
