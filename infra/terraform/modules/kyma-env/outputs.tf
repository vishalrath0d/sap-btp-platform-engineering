# Real fix found while investigating the 2026-08-27 adopt-vs-create
# surprise (see root main.tf's module.kyma_env comment for the full
# story): this module never actually declared these outputs, even
# though root outputs.tf's kyma_dashboard_url has referenced
# `module.kyma_env[0].dashboard_url` since this module was written -
# `try()` silently swallows a reference to a genuinely undeclared module
# output the same way it swallows a missing module instance, so this
# never surfaced as an error, it just always silently resolved to null.
# Harmless on this trial (module count is 0 regardless, see root
# main.tf), but a real latent bug for the non-trial/paid-account case
# this module is kept correct for - fixed here regardless of which case
# applies.
output "id" {
  value = local.kyma_id
}

output "dashboard_url" {
  value = local.kyma_dashboard_url
}
