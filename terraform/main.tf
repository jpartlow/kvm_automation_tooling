terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# TODO: If I'm going to continue with a test, should probably be a `virsh
# pool-list` check instead. But may be better to move pool generation and base
# image acquisition out to a separate module entirely, then coordinate that in
# Bolt in separate plan stages.
data "external" "check_pool_dir" {
  program = ["${path.module}/tools/check_dir.sh", local.platform_image_pool_path]
}

# Define a per platform image pool just once.
resource "libvirt_pool" "image_pool" {
  count = data.external.check_pool_dir.result.exists == "true" ? 0 : 1
  name   = local.platform_pool_name
  type   = "dir"
  target {
    path = local.platform_image_pool_path
  }
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "base_volume_qcow2" {
  name   = "${local.platform_source_image_name}.base.qcow2"
  # use the default pool (/var/lib/libvirt/images) for the base volume
  source = local.platform_source
  format = "qcow2"
}

# The puppet-server/db/postgresql node
module "primary" {
  source = "./modules/vm"
  hostname = "${var.cluster}-${var.platform}-primary"
  pool_name = local.platform_pool_name
  base_volume_name = libvirt_volume.base_volume_qcow2.name
  cpus = var.primary_cpus
  memory = var.primary_memory
  disk_size = var.primary_disk_size
  bridge_ip = var.bridge_ip
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_pool.image_pool, libvirt_volume.base_volume_qcow2]
}

# The puppet-agent nodes
module "agent" {
  source = "./modules/vm"
  count = var.agent_count
  hostname = "${var.cluster}-${var.platform}-agent-${count.index}"
  pool_name = local.platform_pool_name
  base_volume_name = libvirt_volume.base_volume_qcow2.name
  cpus = var.agent_cpus
  memory = var.agent_memory
  disk_size = var.agent_disk_size
  bridge_ip = var.bridge_ip
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
  depends_on = [libvirt_pool.image_pool, libvirt_volume.base_volume_qcow2]
}
