locals {
  gateway_ip = cidrhost(var.network_addresses, 1)
  ssh_public_key = file(var.ssh_public_key_path)
}
