output "id" {
  value       = data.btp_subaccount.this.id
  description = "The subaccount's GUID - every other module references this, never the subdomain."
}

output "region" {
  value       = data.btp_subaccount.this.region
  description = "Confirms the region Terraform actually resolved against."
}
