variable "globalaccount_subdomain" {
  description = "BTP cockpit > Account Explorer, top-level entry."
  type        = string
}

variable "subaccount_subdomain" {
  description = "The trial subaccount's subdomain."
  type        = string
  default     = "4cbf0c12trial-ga"
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

variable "xsuaa_xsappname" {
  description = "Set only after modules/xsuaa's binding has been created once - see this folder's README for the two-phase apply this requires."
  type        = string
  default     = null
}
