locals {
  ssh_public_key = file(var.ssh_public_key_path)
}

module "primary" {
  source = "./modules/vm"
  hostname = "${var.cluster_id}-primary"
  cpus = var.primary_cpus
  memory = var.primary_memory
  disk_size = var.primary_disk_size
  bridge_ip = var.bridge_ip
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
}

module "agent" {
  source = "./modules/vm"
  count = var.agent_count
  hostname = "${var.cluster_id}-agent-${count.index}"
  cpus = var.agent_cpus
  memory = var.agent_memory
  disk_size = var.agent_disk_size
  bridge_ip = var.bridge_ip
  user_password = var.user_password
  ssh_public_key = local.ssh_public_key
}
