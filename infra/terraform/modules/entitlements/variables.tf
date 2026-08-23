variable "subaccount_id" {
  type        = string
  description = "The subaccount GUID to entitle (modules/subaccount's output)."
}

variable "entitlements" {
  description = <<-EOT
    List of { service_name, plan_name, amount? } objects. This module is
    adaptive (looks up what's already entitled via `data
    "btp_subaccount_entitlements"`, only creates what's genuinely
    missing), so a wrong name here mostly just means "won't match
    anything already granted, will try to create it" - `terraform apply`
    is still the real verification step, not `terraform plan` (which
    never validates against the live catalog). This project's own
    current values were corrected once already from documented-but-wrong
    guesses to the real ones, via `btp list accounts/entitlement
    --subaccount <id>` - see main.tf's comment on the `entitlements`
    module call for the full story.
  EOT
  type = list(object({
    service_name = string
    plan_name    = string
    amount       = optional(number)
  }))
}
