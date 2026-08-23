variable "subaccount_id" {
  type = string
}

variable "xsuaa_credentials_json" {
  description = "The raw JSON credentials string from modules/xsuaa's service binding (module.xsuaa.credentials) - this module decodes it internally to read the real xsappname. Passed as a resource ATTRIBUTE (see main.tf), not used in for_each/count - the earlier version of this module gated for_each on a manually-supplied xsappname value, which forced a real two-phase apply (apply, read an output, set a variable, apply again) for no good reason. Attributes CAN depend on values only known after another resource is created in the same apply; for_each/count cannot - this redesign uses the mechanism Terraform actually supports for exactly this pattern."
  type        = string
  sensitive   = true
}

variable "role_collections" {
  description = "List of { name, description, role_template_name } - role_template_name must match a role-template defined in the app's xs-security.json."
  type = list(object({
    name               = string
    description        = string
    role_template_name = string
  }))
}
