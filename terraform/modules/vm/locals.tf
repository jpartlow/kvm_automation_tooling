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

  ##############
  # arm64/x86_64

  is_arm64 = contains(["aarch64", "arm64"], var.arch)
  type_machine = local.is_arm64 ? "virt" : "q35"
  cpu_model = local.is_arm64 ? "cortex-a57" : null

  # For arm64, acpi (for cleaner shutdown behavior) could be supported
  # if we need it, but requires uefi. Leaving that alone atm.
  #
  # But the nulls here are needed to keep the same type structure for
  # terraform ternary to work when returning the x86 features (both
  # branches of the ternary must have the same type sig (object keys,
  # in this case)).
  base_features = {
    acpi    = true
    apic    = null
    smm     = null
    vm_port = null
  }

  # https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM/blob/main/modules/domain_linux/main.tf
  x86_features = {
    acpi    = true
    apic    = { eoi = "on" }
    smm     = { state = "on" }
    vm_port = { state = "off" }
  }

  features = local.is_arm64 ? local.base_features : merge(local.base_features, local.x86_features)
}
