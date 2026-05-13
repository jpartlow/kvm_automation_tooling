locals {
  gateway_ip = cidrhost(var.network_addresses, 1)
  netmask = cidrnetmask(var.network_addresses)
  dhcp_start = cidrhost(var.network_addresses, 2)
  dhcp_end = cidrhost(var.network_addresses, 254)
  ssh_public_key = file(var.ssh_public_key_path)
}
