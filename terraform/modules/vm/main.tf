# Updated to use terraform-provider-libvirt 0.9.x schema.
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

resource "libvirt_volume" "volume_qcow2" {
  name   = "vm-image.${local.hostname}.qcow2"
  pool   = var.pool_name
  capacity      = var.disk_gb * local.gigabyte
  capacity_unit = "bytes"
  backing_store = {
    path   = "${var.base_volume_path}/${var.base_volume_name}"
    format = {
      type = "qcow2"
    }
  }
  target = {
    format = {
      type = "qcow2"
    }
  }
  type = "file"
}

# This resource generates an iso file with the given cloud-init
# configuration.
#
# The 0.8 docs are here https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8/website/docs/r/cloudinit.html.markdown
# But will be out of date for the 0.9 schema, although the principal
# parameters are the same. The main difference is that the generation
# of an actual libvirt-volume is no longer implicit and needs to be
# declared as well.
#
# Use CloudInit to add our ssh-key to the instance, provide some local
# network configuration and perform other initialization tasks.
# Details are in the cloud-init/ templates that are rendered in the
# locals.tf file.
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "cloudinit-${local.hostname}"
  user_data      = local.user_data
  network_config = local.network_config
  meta_data      = local.meta_data
}

resource "libvirt_volume" "volume_cloudinit" {
  name   = "commoninit.iso.${local.hostname}"
  pool   = var.pool_name
  create = {
    content = {
      url = libvirt_cloudinit_disk.commoninit.path
    }
  }
  target = {
    format = {
      type ="iso"
    }
  }
  type = "file"
}

# Create the machine
resource "libvirt_domain" "domain" {
  name   = local.hostname
  type   = "kvm"
  memory = var.mem_mb
  memory_unit = "MB"
  vcpu   = var.cpus
  running = true

  # for debugging atm
  #  on_crash = "preserve"
  # Setting preserve for on_poweroff is throwing:
  #  Error: Domain Creation Failed
  #
  #    with module.vmdomain["agent.u2404t09test-agent-1.ubuntu-2404-amd64"].libvirt_domain.domain,
  #    on modules/vm/main.tf line 66, in resource "libvirt_domain" "domain":
  #    66: resource "libvirt_domain" "domain" {
  #
  #  Failed to define domain in libvirt: unsupported configuration: qemu driver
  #  doesn't support the 'preserve' action for 'on_reboot'/'on_poweroff'
  #  on_poweroff = "preserve"

  os = {
    type = "hvm"
    type_arch = "x86_64"
    type_machine = "q35"
    #    type_machine = "pc-i440fx"
  }

  # https://github.com/donato-marcos/Projeto-Terraform-Libvirt-KVM/blob/main/modules/domain_linux/main.tf
  features = {
    acpi    = true
    apic    = { eoi = "on" }
    smm     = { state = "on" }
    vm_port = { state = "off" }
  }

  cpu = {
    mode = var.cpu_mode
  }

  devices = {
    # This is required to allow the qemu agent to work, which is needed
    # to get the IP address of the machine.
    # In 0.8 this was implicit when qemu_agent was set to true, but in
    # 0.9 we need to declare it explicitly.
    channels = [
      {
        source = {
          unix = {}
        }
        target = {
          virt_io = {
            name  = "org.qemu.guest_agent.0"
          }
        }
      }
    ]

    consoles = [
      # IMPORTANT: this is a known bug on cloud images, since they
      # expect a console we need to pass it
      # https://bugs.launchpad.net/cloud-images/+bug/1573095
      {
        target = {
          type = "serial"
        }
      }
    ]

    # For the cdrom device we need to use scsi for eventual arm64
    # support.
    controllers = [
      {
        type = "scsi"
        model = "virtio-scsi"
      }
    ]

    disks = [
      {
        device = "disk"
        source = {
          volume = {
            pool   = libvirt_volume.volume_qcow2.pool
            volume = libvirt_volume.volume_qcow2.name
          }
        }
        driver = {
          type = "qcow2"
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.volume_cloudinit.pool
            volume = libvirt_volume.volume_cloudinit.name
          }
        }
        target = {
          dev = "sda"
          bus = "scsi"
        }
      }
    ]

    graphics = []
    videos = []

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = var.network_id
          }
        }
        # NOTE: If this fails, terraform destroys the machine, making it
        # difficult to figure out *why* it failed.
        wait_for_ip = {
          timeout = 300    # seconds, default 300
          source  = "any"  # "lease" (DHCP), "agent" (qemu-guest-agent), or "any" (try both)
        }
      }
    ]
  }
}

data "libvirt_domain_interface_addresses" "domain_addresses" {
  domain = libvirt_domain.domain.name
  source = "any"
}

output "vmdomain_details" {
  value = {
    (local.hostname) = {
      platform = local.platform
      role     = local.role
      ip_addresses = flatten([
        for iface in data.libvirt_domain_interface_addresses.domain_addresses.interfaces:
          [for a in iface.addrs : a.addr]
      ])
    }
  }
}
