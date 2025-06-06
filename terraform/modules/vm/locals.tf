locals {
  role = split(".", var.vm_id)[0]
  hostname = split(".", var.vm_id)[1]
  platform = split(".", var.vm_id)[2]
  # The path to the cloud-init configuration templates
  cloud_init_path = "${path.module}/../../../cloud-init"
  user_data = templatefile(
    "${local.cloud_init_path}/user-data.yaml.tftpl",
    {
      user_name          = var.user_name,
      ssh_authorized_key = var.ssh_public_key,
      user_password      = var.user_password,
      os                 = var.os,
      domain_name        = var.domain_name,
    }
  )
  network_config = templatefile(
    "${local.cloud_init_path}/network-config.yaml.tftpl",
    {
      gateway_ip = var.gateway_ip,
      os         = var.os,
    }
  )
  meta_data = templatefile(
    "${local.cloud_init_path}/meta-data.yaml.tftpl",
    {
      instance_id = "i-${uuid()}",
      hostname = local.hostname,
    }
  )
  gigabyte = 1024 * 1024 * 1024
}
