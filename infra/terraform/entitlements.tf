# Entitlements grant the subaccount quota to actually use a service - they
# have to exist before the corresponding environment_instance/service
# resources in environments.tf and elsewhere can succeed. service_name and
# plan_name below are the commonly-documented values for a trial landscape;
# they are the single thing in this whole Terraform module NOT yet verified
# against this specific account (that needs an authenticated `btp` CLI
# session or the cockpit's Entitlements screen - see infra/terraform/README.md's
# "before your first plan" checklist). `terraform plan` against the real
# account is expected to be the actual verification step for these two
# values - if either is wrong, the API will say so explicitly rather than
# silently entitling the wrong thing.

resource "btp_subaccount_entitlement" "cloudfoundry" {
  subaccount_id = data.btp_subaccount.trial.id
  service_name  = "cloudfoundry"
  plan_name     = "standard" # trial subaccounts typically get this auto-entitled already;
  # declared explicitly here anyway so the whole landscape is
  # reproducible from `terraform apply` alone, not partly
  # dependent on cockpit defaults nobody wrote down.
}

resource "btp_subaccount_entitlement" "kyma" {
  subaccount_id = data.btp_subaccount.trial.id
  service_name  = "kymaruntime"
  plan_name     = "trial"
}

resource "btp_subaccount_entitlement" "hana_cloud" {
  subaccount_id = data.btp_subaccount.trial.id
  service_name  = "hana-cloud-trial"
  plan_name     = "hana-cloud-trial"
}
