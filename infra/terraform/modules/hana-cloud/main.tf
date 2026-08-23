# Real gap hit live, only found once procurement-core's MTA deploy
# actually ran against this trial: the "hana"/"hdi-shared" plan (already
# entitled and used by services/procurement-core/mta.yaml's HDI
# container resource) provisions an HDI *container* on an *existing*
# SAP HANA database - it does not create that database. Confirmed
# straight from the marketplace's own plan description ("Manage schemas
# and HDI containers on an existing SAP HANA database") and from the
# live deploy failure: "Service broker error: ... Can not create service
# instance 'procurement-core-db': There is no database available. Ensure
# that you have a database available in space 'dev' within organization
# '4cbf0c12trial'."
#
# The real, separate offering that creates the database itself is
# "hana-cloud" - confirmed via `cf marketplace -e hana-cloud` against
# this live subaccount, not guessed: plans hana-cloud-connection-free,
# relational-data-lake-free, hana-free. `hana-free` is the one that
# provisions an actual (free-tier) HANA Cloud instance. It already shows
# up in this subaccount's marketplace without any entitlement change -
# no `modules/entitlements` update needed, only this instance.
#
# Not adaptive/adopt-existing like modules/cloudfoundry-env or
# modules/kyma-env - unlike those, there's no SAP-provisioned default
# HANA Cloud instance sitting in a trial subaccount already, so there is
# nothing to adopt on first apply. A plain resource, same shape as the
# working modules/xsuaa (also a plain btp_subaccount_service_instance,
# no adopt-lookup) - matching this project's own precedent rather than
# adding lookup complexity a real trial account doesn't need here.
#
# Subaccount-scoped (not tied to one CF space) is deliberate, not
# incidental: SAP's own model for hdi-shared is one shared database per
# subaccount, HDI containers requested from any space/environment under
# it - the "hana" broker discovers this instance across the whole
# subaccount, the same way modules/xsuaa's subaccount-level XSUAA
# instance backs role collections used from any space.
resource "btp_subaccount_service_instance" "hana_cloud" {
  subaccount_id         = var.subaccount_id
  name                  = "${var.name_prefix}-hana-cloud"
  service_offering_name = "hana-cloud"
  serviceplan_name      = "hana-free"
  # Real bug hit live: leaving `parameters` unset entirely isn't the same
  # as "no parameters" to this broker - the create call failed with
  # "Failed to unmarshal parameters: unexpected end of JSON input", i.e.
  # it tried to JSON-parse an empty string. An explicit empty object is
  # the real fix, matching modules/xsuaa always passing `parameters`
  # rather than omitting it.
  parameters = "{}"

  timeouts = {
    # Real HANA Cloud provisioning is slow (tens of minutes, not seconds
    # - unlike XSUAA/role collections above), same order of magnitude as
    # Kyma cluster creation elsewhere in this project. Provider default
    # timeout risks a false failure on a real apply; set explicitly
    # rather than discovering the default is too short mid-run.
    create = "60m"
    delete = "30m"
  }
}
