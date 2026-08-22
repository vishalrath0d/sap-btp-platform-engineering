# NOT USABLE YET. The BTP trial provides exactly one subaccount total -
# there is no second subaccount to point subaccount_subdomain at. This
# file exists (rather than being omitted) purely to keep the
# environments/<env>/terraform.tfvars convention consistent and to make
# obvious exactly what needs to change once a real qa subaccount exists:
# just this file, main.tf/modules/ need zero changes.

environment             = "qa"
globalaccount_subdomain = "CHANGE_ME"
subaccount_subdomain    = "CHANGE_ME_NO_QA_SUBACCOUNT_YET"
region                  = "us10"
kyma_administrators     = ["you@example.com"]
