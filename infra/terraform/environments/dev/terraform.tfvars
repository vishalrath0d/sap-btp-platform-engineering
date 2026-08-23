environment             = "dev"
globalaccount_subdomain = "4cbf0c12trial-ga" # confirmed from the real Account
# Explorer page: "Subdomain: 4cbf0c12trial-ga"
# - genuinely DIFFERENT from the subaccount's
# own subdomain below (no "-ga") - my earlier
# guess that they were the same value was wrong
subaccount_subdomain = "4cbf0c12trial" # was wrongly "4cbf0c12trial-ga" - confirmed
# against the real cockpit General panel,
# no "-ga" suffix exists
region = "us10" # confirmed: matches the real CF API endpoint
# (api.cf.us10-001.hana.ondemand.com) shown in the
# cockpit's own Cloud Foundry Environment panel
# Real bug fixed here too, though it turned out not to be Kyma's actual
# blocker: a placeholder "you@example.com" left from earlier scaffolding,
# never replaced - fixed to the real account owner's actual email
# regardless, since it's still the right value once Kyma is enabled.
kyma_administrators = ["vishaljanusingrathod@gmail.com"]

# false until SAP approves the trial Kyma request (sent, pending - see
# docs/next/next.md) - see variables.tf's kyma_enabled description and
# main.tf's module.kyma_env comment for the full story. Flip to true once
# approved; nothing else in this repo needs to change.
kyma_enabled = false

# btp_username / btp_password / xsuaa_xsappname: intentionally NOT here,
# even as placeholders - Local-execution-mode HCP Terraform workspaces
# don't have a Variables UI at all, so these are supplied as TF_VAR_*
# env vars by the GitHub Actions workflows instead, sourced from repo
# secrets (BTP_USERNAME, BTP_PASSWORD, XSUAA_XSAPPNAME) - see ../../README.md.
