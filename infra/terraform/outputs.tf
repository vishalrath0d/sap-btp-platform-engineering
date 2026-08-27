output "subaccount_id" {
  value = module.subaccount.id
}

output "subaccount_region" {
  value = module.subaccount.region
}

output "cloudfoundry_org_id" {
  value = module.cloudfoundry_env.id
}

output "kyma_dashboard_url" {
  value       = try(module.kyma_env[0].dashboard_url, null)
  description = <<-EOT
    null on this trial, always - module.kyma_env's count is 0 (see
    main.tf's comment: this trial's Kyma cluster exists but isn't
    manageable/discoverable via this module's API at all). The real
    dashboard URL for this trial's actual cluster is
    https://dashboard.kyma.cloud.sap/?kubeconfigID=E9B58919-D384-43E1-A3BA-8F6DB309F57B
    (from the real SAP approval email, 2026-08-25) - document/use that
    directly, don't expect this output to ever be non-null here. Stays
    real and correct for a non-trial/paid subaccount where the module
    actually instantiates.
  EOT
}

# No xsuaa_credentials output anymore - module.xsuaa is gated to count=0
# (see main.tf's comment: a same-xsappname duplicate of procurement-
# core's own MTA-created XSUAA instance genuinely conflicts at the
# broker level). role_collections now gets the real xsappname from
# var.xsuaa_xsappname, fetched live from that MTA-created instance via
# cf create-service-key (see terraform-apply.yml), not from this module.
