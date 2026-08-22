variable "subaccount_id" {
  type = string
}

variable "xsuaa_xsappname" {
  description = "The real XSUAA xsappname - only known after modules/xsuaa's binding is created once (XSUAA assigns it at bind time). Leave null on the first apply; this whole module no-ops (count=0 on every collection) until it's set."
  type        = string
  default     = null
}

variable "role_collections" {
  description = "List of { name, description, role_template_name } - role_template_name must match a role-template defined in the app's xs-security.json."
  type = list(object({
    name               = string
    description        = string
    role_template_name = string
  }))
}
