variable "subaccount_id" {
  type = string
}

variable "name" {
  type = string
}

variable "url" {
  type        = string
  description = "Must be reachable from BTP - not localhost. See environments/dev/README.md for why this module isn't instantiated yet."
}

variable "proxy_type" {
  type    = string
  default = "OnPremise"
}

variable "authentication" {
  type    = string
  default = "NoAuthentication"
}

variable "description" {
  type    = string
  default = ""
}
