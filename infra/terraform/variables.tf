variable "globalaccount_subdomain" {
  description = "BTP cockpit > Account Explorer, top-level entry."
  type        = string
}

variable "subaccount_subdomain" {
  description = "The subaccount's subdomain for whichever environment is being applied. Deliberately NO default here - this file is now shared across dev/qa/prod (see main.tf's header comment), and a default matching one specific environment's subaccount would risk a qa/prod apply silently targeting dev's subaccount if a tfvars file ever forgot to set it. Always set explicitly in environments/<env>/terraform.tfvars."
  type        = string
}

variable "region" {
  description = "BTP technical region ID, e.g. 'us10' for 'US East (VA) - AWS'."
  type        = string
  default     = "us10"
}

variable "btp_username" {
  description = "SAP Universal ID. Set as an HCP Terraform workspace environment variable (sensitive), not in a .tfvars file."
  type        = string
  sensitive   = true
}

variable "btp_password" {
  type      = string
  sensitive = true
}

variable "kyma_administrators" {
  description = "List of emails to set as Kyma cluster administrators - must include whoever applies this."
  type        = list(string)
}

variable "kyma_enabled" {
  description = <<-EOT
    Gates whether module.kyma_env is instantiated at all. Default false -
    this trial account has no self-service Kyma provisioning (confirmed
    twice over: two live `terraform apply` CREATION_FAILED results, then
    the identical failure trying the cockpit's own "Enable Kyma" wizard
    directly - see modules/kyma-env/main.tf's own comment). A trial Kyma
    instance must be requested from SAP and is reviewed within up to a
    month (request sent, see docs/next/next.md for the tracking note) -
    until that's approved, every apply would otherwise fail on this one
    resource every single time, for a reason no retry fixes.

    The module itself is untouched and stays fully correct - flip this to
    true (in environments/<env>/terraform.tfvars, not here) once SAP
    approves the request, or immediately on a real/paid account where
    this restriction doesn't apply.
  EOT
  type        = bool
  default     = false
}

variable "environment" {
  description = "Which environment this apply targets - drives naming (procureiq-<environment>) and must match the terraform.tfvars file actually being used (environments/<environment>/terraform.tfvars). No default on purpose: forgetting to set this should fail loudly, not silently default to dev."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}
