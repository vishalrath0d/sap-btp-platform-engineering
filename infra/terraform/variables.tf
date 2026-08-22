variable "globalaccount_subdomain" {
  description = "The BTP global account's subdomain (BTP cockpit > Account Explorer, top-level entry). For a fresh trial this is usually the same value as the trial subaccount's subdomain unless something was renamed - confirm both independently rather than assuming they match."
  type        = string
}

variable "subaccount_subdomain" {
  description = "The trial subaccount's subdomain, e.g. 4cbf0c12trial-ga (BTP cockpit > your subaccount > Overview)."
  type        = string
}

variable "region" {
  description = <<-EOT
    BTP technical region ID, not the friendly cockpit name - e.g. 'us10' for
    'US East (VA) - AWS'. This is the single value in this whole module most
    worth double-checking in the cockpit before the first `terraform plan`:
    a wrong region makes the provider fail loudly against the real API
    rather than silently misbehave, which is the least-bad way for this to
    go wrong, but still worth getting right the first time.
  EOT
  type        = string
  default     = "us10"
}

variable "btp_username" {
  description = "SAP Universal ID (P-/S-user email) used to log into the BTP trial. Provide via TF_VAR_btp_username or terraform.tfvars (gitignored) - never commit this. A real (non-trial) landscape would use a technical/service user instead of a personal login."
  type        = string
  sensitive   = true
}

variable "btp_password" {
  description = "Password for btp_username. Same handling as btp_username - provide via env var or gitignored .tfvars, never commit."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Which promotion stage this apply targets - drives naming/labels. The trial only has one real subaccount, so dev/qa/prod here are logical labels within it for now, not separate subaccounts (that needs a paid landscape - see infra/terraform/README.md)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}
