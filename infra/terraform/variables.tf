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

variable "xsuaa_xsappname" {
  description = <<-EOT
    The real, dynamically-assigned xsappname (e.g. 'procurement-core!t700023')
    from procurement-core's own MTA-created XSUAA instance - fetched live via
    `cf create-service-key` against the real deployed instance (see
    terraform-apply.yml), not from a separate Terraform-managed XSUAA
    instance. A second, Terraform-only XSUAA "application" plan instance
    with the same xsappname genuinely conflicts with the MTA's own one -
    confirmed live: creating procurement-core-xsuaa failed every time with
    a broker-side NPE (ScaleOutLandscapeImpl.getEndpoints(), scaleOutLandscape
    null) for as long as modules/xsuaa's duplicate existed alongside it,
    and stopped the moment that duplicate was destroyed. Real two-phase
    apply as a result, restoring what modules/role-collections' own
    variables.tf already once did before a redesign assumed (wrongly, as
    it turned out) that a same-xsappname Terraform-managed instance was a
    safe way to learn this value in one apply: deploy procurement-core
    first (its own xsuaa instance gets created for real), THEN apply
    terraform with this variable set to the value that deploy produced.
    Empty string is tolerated (see modules/role-collections/main.tf) for
    a genuinely first-ever apply, before any deploy has happened yet.
  EOT
  type        = string
  default     = ""
}

variable "environment" {
  description = "Which environment this apply targets - drives naming (procureiq-<environment>) and must match the terraform.tfvars file actually being used (environments/<environment>/terraform.tfvars). No default on purpose: forgetting to set this should fail loudly, not silently default to dev."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}
