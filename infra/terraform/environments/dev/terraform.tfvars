environment             = "dev"
globalaccount_subdomain = "CHANGE_ME"
subaccount_subdomain    = "4cbf0c12trial-ga"
region                  = "us10"
kyma_administrators     = ["you@example.com"]

# btp_username / btp_password / xsuaa_xsappname: intentionally NOT here,
# even as placeholders - Local-execution-mode HCP Terraform workspaces
# don't have a Variables UI at all, so these are supplied as TF_VAR_*
# env vars by the GitHub Actions workflows instead, sourced from repo
# secrets (BTP_USERNAME, BTP_PASSWORD, XSUAA_XSAPPNAME) - see ../../README.md.
