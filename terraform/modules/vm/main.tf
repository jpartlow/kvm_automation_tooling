# Originally from: https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.1/examples/v0.13/ubuntu/ubuntu-example.tf
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

resource "libvirt_pool" "ubuntu" {
  name   = "ubuntu"
  type   = "dir"
  target {
    path = "/var/lib/libvirt/images/ubuntu-2404-amd64"
  }
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"
  size   = var.disk_size
}

locals {
  # The path to the cloud-init configuration templates
  cloud_init_path = "${path.module}/../../../cloud-init"
  user_data = templatefile(
    "${local.cloud_init_path}/user-data.yaml.tftpl",
    {
      ssh_authorized_key = var.ssh_public_key,
      user_password      = var.user_password,
    }
  )
  network_config = templatefile(
    "${local.cloud_init_path}/network-config.yaml.tftpl",
    {
      bridge_ip = var.bridge_ip,
    }
  )
  meta_data = templatefile(
    "${local.cloud_init_path}/meta-data.yaml.tftpl",
    {
      hostname = var.hostname,
    }
  )
}

# for more info about parameters check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = locals.user_data
  network_config = locals.network_config
  meta_data      = locals.meta_data
  pool           = libvirt_pool.ubuntu.name
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform-2"
  memory = var.memory
  vcpu   = var.cpus

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
     bridge = "virbr0"
     # Should test with this enabled
     # wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  #  graphics {
  #    type        = "spice"
  #    listen_type = "address"
  #    autoport    = true
  #  }
}
