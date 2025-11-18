terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

resource "libvirt_network" "network" {
  name = var.cluster_id
  mode = "nat"
  domain = var.domain_name
  addresses = [var.network_addresses]
  dhcp {
    enabled = true
  }
  autostart = true
  dns {
    local_only = true
  }
}

module "vmdomain" {
  source = "./modules/vm"
  for_each = var.vm_specs
  vm_id = each.key
  pool_name = each.value.pool_name
  base_volume_name = each.value.base_volume_name
  os = each.value.os
  cpu_mode = each.value.cpu_mode
  cpus = each.value.cpus
  mem_mb = each.value.mem_mb
  disk_gb = each.value.disk_gb
  gateway_ip = local.gateway_ip
  network_id = libvirt_network.network.id
  domain_name = var.domain_name
  user_name = var.user_name
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_network.network]
}
