# The real production counterpart to
# services/procurement-core/srv/lib/destinations.json's local simulation -
# see docs/concepts/11-connectivity-cloud-connector.md.
resource "btp_subaccount_destination" "this" {
  subaccount_id  = var.subaccount_id
  name           = var.name
  url            = var.url
  type           = "HTTP"
  proxy_type     = var.proxy_type
  authentication = var.authentication
  description    = var.description
}
