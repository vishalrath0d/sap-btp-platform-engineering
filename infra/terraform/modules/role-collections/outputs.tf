output "role_collection_ids" {
  value = { for k, rc in btp_subaccount_role_collection.this : k => rc.id }
}
