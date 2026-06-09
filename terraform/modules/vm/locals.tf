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

  is_arm64 = (var.arch == "aarch64")
  guest_and_host_same_arch = (var.arch == var.host_arch)

  # In general, if guest and host arch don't match we need to use
  # qemu, but if they do match we can use kvm for better performance.
  # (assumes host has kvm support though)
  domain_type = local.guest_and_host_same_arch ? coalesce(var.domain_type, "kvm") : "qemu"

  type_machine = local.is_arm64 ? "virt" : "q35"

  # Currently, we only provide cpu_mode as an input parameter to allow
  # specifying 'host-model' or 'host-passthrough' for nested
  # virtualization.
  #
  # If cpu_mode has been explicitly set in the input variables, we
  # will honor that and not set cpu_model, otherwise we'll set
  # cpu_mode/cpu_model based on the architectures.
  #
  # host  guest
  #       amd64                    arm64
  # amd64 host-model               custom (cortex-a57)
  # arm64 custom (Skylake-Client)  host-model
  #
  # TODO: provide a cpu_model parameter.
  default_custom_cpu_model = (local.is_arm64 ?
    "cortex-a57" :
    "Skylake-Client") # x86_64-v4 (v2 is minimal for El9...)
  cpu_mode_explicitly_set = (var.cpu_mode != null)
  derived_cpu_mode = (local.cpu_mode_explicitly_set ?
    var.cpu_mode :
    (local.guest_and_host_same_arch ? "host-model" : "custom"))
  derived_cpu_model = ((local.derived_cpu_mode == "custom") ?
    local.default_custom_cpu_model :
    null)

  # The nulls here are needed to keep the same type structure for
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

  # Alma 9, 10 and Debian 11 arm64 images don't seem to have
  # secureboot support, so we need to disable it for those platforms
  # to avoid boot failures when trying to load the UEFI firmware.
  platforms_without_secureboot = [
    "almalinux-9-aarch64",
    "almalinux-10-aarch64",
    "debian-11-arm64",
  ]
  arm64_no_secureboot_firmware_info = {
    features = [
      {
        name = "enrolled-keys"
        enabled = "no"
      },
      {
        name = "secure-boot"
        enabled = "no"
      },
    ]
  }
  firmware_info = (
    local.is_arm64 &&
    contains(local.platforms_without_secureboot, local.platform)
  ) ? local.arm64_no_secureboot_firmware_info : null
}
