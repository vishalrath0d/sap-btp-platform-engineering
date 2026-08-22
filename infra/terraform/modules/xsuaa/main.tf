resource "btp_subaccount_service_instance" "xsuaa" {
  subaccount_id         = var.subaccount_id
  name                  = "${var.name_prefix}-xsuaa"
  service_offering_name = "xsuaa"
  serviceplan_name      = "application"
  parameters            = file(var.xs_security_json_path)
}

resource "btp_subaccount_service_binding" "xsuaa" {
  subaccount_id       = var.subaccount_id
  name                = "${var.name_prefix}-xsuaa-binding"
  service_instance_id = btp_subaccount_service_instance.xsuaa.id
}
