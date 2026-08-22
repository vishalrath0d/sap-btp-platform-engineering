provider "btp" {
  globalaccount = var.globalaccount_subdomain
  username      = var.btp_username
  password      = var.btp_password
  # cli_server_url defaults to the standard BTP CLI server; only override
  # if targeting a non-standard landscape, which a trial never is.
}
