# Originally from: https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.1/examples/v0.13/ubuntu/ubuntu-example.tf
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

locals {
  # The path to the cloud-init configuration file
  cloud_init_path = "${path.module}/../cloud-init/ubuntu-2404-amd64"
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
  name = "ubuntu-qcow2"
#  pool = "default"
  pool   = libvirt_pool.ubuntu.name
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${local.cloud_init_path}/user-data.yaml")
}

data "template_file" "network_config" {
  template = file("${local.cloud_init_path}/network-config.yaml")
}

data "template_file" "meta_data" {
  template = file("${local.cloud_init_path}/meta-data.yaml")
}

# for more info about parameters check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  meta_data      = data.template_file.meta_data.rendered
  pool           = libvirt_pool.ubuntu.name
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform-2"
  memory = "2048"
  vcpu   = 2

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
