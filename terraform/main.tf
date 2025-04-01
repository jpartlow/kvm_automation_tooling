terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
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

# The puppet-server/db/postgresql node
module "primary" {
  source = "./modules/vm"
  count = var.primary_count
  cluster_id = var.cluster_id
  hostname = "primary"
  pool_name = var.pool_name
  base_volume_name = var.base_volume_name
  cpu_mode = var.cpu_mode
  cpus = var.primary_cpus
  memory = var.primary_memory
  disk_size = var.primary_disk_size
  gateway_ip = local.gateway_ip
  network_id = libvirt_network.network.id
  user_name = var.user_name
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_network.network]
}

# The puppet-agent nodes
module "agent" {
  source = "./modules/vm"
  count = var.agent_count
  cluster_id = var.cluster_id
  hostname = "agent-${count.index}"
  pool_name = var.pool_name
  base_volume_name = var.base_volume_name
  cpu_mode = var.cpu_mode
  cpus = var.agent_cpus
  memory = var.agent_memory
  disk_size = var.agent_disk_size
  gateway_ip = local.gateway_ip
  network_id = libvirt_network.network.id
  user_name = var.user_name
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_network.network]
}
