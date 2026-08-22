variable "subaccount_id" {
  type = string
}

variable "org_name" {
  type        = string
  description = "The Cloud Foundry org name this creates - what `cf orgs` will show."
}

variable "landscape_label" {
  type        = string
  description = "CF landscape label, e.g. 'cf-us10' for US East (VA) - AWS. NOTE the 'cf-' prefix: this is the region ID prefixed, not the bare region ID used elsewhere (e.g. modules/kyma-env uses a bare region/provider name) - a real, confirmed-by-research distinction, not a typo."
}

variable "entitlement_dependency" {
  description = "Pass the entitlements module's entitlement_ids output here so Terraform's dependency graph orders entitlement-before-environment correctly (a reference alone isn't enough since this module doesn't otherwise read that value)."
  type        = any
  default     = null
}
