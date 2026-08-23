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
# Real bug hit live: a placeholder "you@example.com" left here from
# earlier scaffolding, never replaced, is the near-certain cause of Kyma
# creation failing in ~40 seconds - too fast to be real cluster
# provisioning (which genuinely takes 15-20 minutes), consistent with an
# immediate administrator-email validation rejection before provisioning
# ever starts. Set to the real account owner's actual email.
kyma_administrators = ["vishaljanusingrathod@gmail.com"]

# btp_username / btp_password / xsuaa_xsappname: intentionally NOT here,
# even as placeholders - Local-execution-mode HCP Terraform workspaces
# don't have a Variables UI at all, so these are supplied as TF_VAR_*
# env vars by the GitHub Actions workflows instead, sourced from repo
# secrets (BTP_USERNAME, BTP_PASSWORD, XSUAA_XSAPPNAME) - see ../../README.md.
