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

# SAP approved the trial Kyma request 2026-08-25 (email confirmed,
# cluster live - shoot "cd97393", domain cd97393.kyma.ondemand.com, us10/
# AWS - confirmed directly via kubectl 2026-08-27). Flipped to true -
# though, found the same day: this module's adopt-lookup can't actually
# see this trial's Kyma cluster at all (a different, deeper finding than
# expected - see root main.tf's module.kyma_env comment for the full
# story), so its resource count is hardcoded to 0 regardless of this
# variable's value now. Left true anyway because it's still real,
# accurate landscape state - Kyma IS enabled/in-use for this environment,
# just not through this Terraform module; other tooling/docs (kyma-
# deploy.yml, README) read this fact directly, not through Terraform.
# Real, load-bearing operational fact regardless: this trial cluster
# auto-expires and is deleted 14 days after creation (SAP's own
# documented policy) - i.e. around 2026-09-08 - not a one-time setup.
kyma_enabled = true

# btp_username / btp_password / xsuaa_xsappname: intentionally NOT here,
# even as placeholders - Local-execution-mode HCP Terraform workspaces
# don't have a Variables UI at all, so these are supplied as TF_VAR_*
# env vars by the GitHub Actions workflows instead, sourced from repo
# secrets (BTP_USERNAME, BTP_PASSWORD, XSUAA_XSAPPNAME) - see ../../README.md.
