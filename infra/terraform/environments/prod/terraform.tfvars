# NOT USABLE YET. The BTP trial provides exactly one subaccount total -
# there is no second subaccount to point subaccount_subdomain at. This
# file exists (rather than being omitted) purely to keep the
# environments/<env>/terraform.tfvars convention consistent and to make
# obvious exactly what needs to change once a real prod subaccount exists:
# just this file, main.tf/modules/ need zero changes.

environment             = "prod"
globalaccount_subdomain = "CHANGE_ME"
subaccount_subdomain    = "CHANGE_ME_NO_PROD_SUBACCOUNT_YET"
region                  = "us10"
kyma_administrators     = ["you@example.com"]
