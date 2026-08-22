variable "subaccount_id" {
  type        = string
  description = "The subaccount GUID to entitle (modules/subaccount's output)."
}

variable "entitlements" {
  description = <<-EOT
    List of { service_name, plan_name, amount? } objects. service_name/
    plan_name for the trial services this project uses (cloudfoundry,
    kymaruntime, hana-cloud-trial) are the commonly-documented trial
    values, NOT yet verified against this specific account - the first
    real `terraform plan` is the actual verification step (see
    environments/dev/README.md's "before your first plan" checklist).
  EOT
  type = list(object({
    service_name = string
    plan_name    = string
    amount       = optional(number)
  }))
}
