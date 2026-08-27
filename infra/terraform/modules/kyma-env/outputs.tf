# Temporary diagnostic output (to be deleted after use) - the plan run
# after flipping kyma_enabled=true showed "will be created" instead of
# adopting the real, already-provisioned trial cluster, which shouldn't
# happen per this module's own adopt-lookup design (main.tf's comment).
# Surfacing the raw data source result to see why before risking a real
# apply against it.
output "debug_all_environment_instances" {
  value = data.btp_subaccount_environment_instances.all.values
}

output "debug_kyma_exists" {
  value = local.kyma_exists
}
