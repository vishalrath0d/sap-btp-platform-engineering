variable "subaccount_id" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "e.g. 'procurement-core' - service instance/binding names become '<prefix>-xsuaa'/'<prefix>-xsuaa-binding'."
}

variable "xs_security_json_path" {
  type        = string
  description = "Path to the app's xs-security.json - the single source of truth for the role model, referenced from here rather than duplicated."
}
