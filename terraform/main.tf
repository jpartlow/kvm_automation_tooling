terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "~> 0.9.7"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

resource "libvirt_network" "network" {
  name = var.cluster_id
  autostart = true
  dns = {
    enabled = "yes"
  }
  domain = {
    name = var.domain_name
    local_only = "yes"
  }
  forward = {
    mode = "nat"
  }
  ips = [
    {
      address = local.gateway_ip
      netmask = local.netmask
      dhcp = {
        ranges = [
          {
            start = local.dhcp_start
            end   = local.dhcp_end
          },
        ]
      }
      family = "ipv4"
    }
  ]
}

module "vmdomain" {
  source = "./modules/vm"
  for_each = var.vm_specs
  vm_id = each.key
  pool_name = each.value.pool_name
  base_volume_name = each.value.base_volume_name
  os = each.value.os
  # Libvirt expects "x86_64" and "aarch64" for the arch parameter
  arch = lookup({
    amd64 = "x86_64",
    arm64 = "aarch64"
  }, each.value.arch, each.value.arch)  # default to the provided value
  type = each.value.type
  cpu_mode = each.value.cpu_mode
  cpus = each.value.cpus
  mem_mb = each.value.mem_mb
  disk_gb = each.value.disk_gb
  gateway_ip = local.gateway_ip
  network_id = libvirt_network.network.name
  domain_name = var.domain_name
  user_name = var.user_name
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_network.network]
}
