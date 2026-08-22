# The real production counterpart to services/procurement-core/srv/lib/
# destinations.json's local simulation (see
# docs/concepts/11-connectivity-cloud-connector.md) - btp_subaccount_destination
# is a genuine BTP Terraform resource, confirmed against the actual
# SAP/btp v1.26.0 provider schema while building this file (not guessed).
#
# Left commented out rather than applied: it needs an internet-reachable
# URL for the legacy system (legacy-erp-gateway currently only runs on
# localhost) and proxy_type would only become "OnPremise" once a real
# Cloud Connector tunnel exists - applying this before either of those is
# true would create a destination that can never actually resolve.
# Uncomment once legacy-erp-gateway (or an equivalent) is reachable from
# BTP, either deployed itself or tunneled via Cloud Connector.

# resource "btp_subaccount_destination" "legacy_supplier_erp" {
#   subaccount_id = data.btp_subaccount.trial.id
#   name          = "LEGACY_SUPPLIER_ERP"
#   url           = "https://<legacy-erp-gateway-reachable-url>"
#   type          = "HTTP"
#   proxy_type    = "OnPremise" # or "Internet" if legacy-erp-gateway ends up
#                                 # deployed to CF/Kyma instead of tunneled
#   authentication = "NoAuthentication"
#   description    = "Mirrors services/procurement-core/srv/lib/destinations.json's local simulation."
# }
