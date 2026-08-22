environment             = "dev"
globalaccount_subdomain = "4cbf0c12trial" # confirmed from the cockpit breadcrumb
                                            # (Trial Home > 4cbf0c12trial > trial) -
                                            # same value labels both the global account
                                            # and, one level down, the subaccount itself
subaccount_subdomain    = "4cbf0c12trial" # was wrongly "4cbf0c12trial-ga" - confirmed
                                            # against the real cockpit General panel,
                                            # no "-ga" suffix exists
region                  = "us10" # confirmed: matches the real CF API endpoint
                                   # (api.cf.us10-001.hana.ondemand.com) shown in the
                                   # cockpit's own Cloud Foundry Environment panel
kyma_administrators     = ["you@example.com"]

# btp_username / btp_password / xsuaa_xsappname: intentionally NOT here,
# even as placeholders - Local-execution-mode HCP Terraform workspaces
# don't have a Variables UI at all, so these are supplied as TF_VAR_*
# env vars by the GitHub Actions workflows instead, sourced from repo
# secrets (BTP_USERNAME, BTP_PASSWORD, XSUAA_XSAPPNAME) - see ../../README.md.
