output "role_collection_ids" {
  value       = { for k, rc in btp_subaccount_role_collection.this : k => rc.id }
  description = "Only the role collections this apply actually created (not the ones XSUAA already auto-created and this module adopted instead)."
}

output "adopted_role_collections" {
  value       = local.existing_names
  description = "Names that already existed (XSUAA auto-created, creationType XSSECURITY) before this apply and were left alone."
}
