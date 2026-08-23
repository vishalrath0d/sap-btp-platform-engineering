variable "subaccount_id" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "e.g. 'procureiq-dev' - service instance name becomes '<prefix>-hana-cloud'. Subaccount-scoped, not tied to one service, since any HDI container in this subaccount (any space) can use the same database."
}
