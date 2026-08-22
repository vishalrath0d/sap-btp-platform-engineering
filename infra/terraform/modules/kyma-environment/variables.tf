variable "subaccount_id" {
  type = string
}

variable "name" {
  type = string
}

variable "plan_name" {
  type        = string
  description = "'trial' for a trial subaccount's Kyma; a real (non-trial) landscape names plans after the hyperscaler instead (e.g. 'aws', 'azure', 'gcp') - confirmed via a real applied SAP-samples/btp-terraform-samples module. Verify which applies to this specific account before the first apply."
  default     = "trial"
}

variable "administrators" {
  type        = list(string)
  description = "At least the applying user's email - Kyma provisioning requires an explicit administrators list, it isn't inferred from who ran terraform apply."
}
