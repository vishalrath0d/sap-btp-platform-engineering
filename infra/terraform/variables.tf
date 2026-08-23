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

variable "environment" {
  description = "Which environment this apply targets - drives naming (procureiq-<environment>) and must match the terraform.tfvars file actually being used (environments/<environment>/terraform.tfvars). No default on purpose: forgetting to set this should fail loudly, not silently default to dev."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}
