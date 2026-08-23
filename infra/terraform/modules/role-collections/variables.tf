variable "subaccount_id" {
  type = string
}

variable "xsuaa_xsappname" {
  description = "The real, dynamically-assigned xsappname from procurement-core's own MTA-created XSUAA instance (e.g. 'procurement-core!t700023') - a plain, manually-supplied value again, not read from a Terraform-managed XSUAA instance's credentials. A same-xsappname Terraform-managed 'application' plan XSUAA instance genuinely conflicts with the MTA's own one at the broker level (real live failure, see infra/terraform/variables.tf's xsuaa_xsappname description) - the credentials-JSON version this replaced was solving a nonexistent problem at the cost of creating a real one. Empty string tolerated for a genuinely first-ever apply."
  type        = string
  default     = ""
}

variable "role_collections" {
  description = "List of { name, description, role_template_name } - role_template_name must match a role-template defined in the app's xs-security.json."
  type = list(object({
    name               = string
    description        = string
    role_template_name = string
  }))
}
