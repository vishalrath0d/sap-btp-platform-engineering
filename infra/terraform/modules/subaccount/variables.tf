variable "subdomain" {
  description = "The subaccount's subdomain (BTP cockpit > subaccount > Overview)."
  type        = string
}

variable "region" {
  description = "BTP technical region ID, e.g. 'us10'. Required alongside subdomain by the provider's data source - see main.tf's comment."
  type        = string
}
