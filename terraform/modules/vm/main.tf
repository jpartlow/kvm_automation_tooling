# Originally from: https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.1/examples/v0.13/ubuntu/ubuntu-example.tf
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "volume_qcow2" {
  name   = "vm-image.${local.identifier}.qcow2"
  pool   = var.pool_name
  base_volume_name = var.base_volume_name
  base_volume_pool = "default"
  format = "qcow2"
  size   = var.disk_size * local.gigabyte # need to use cloud-init to grow the partition?
}

# for more info about parameters check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso.${local.identifier}"
  user_data      = local.user_data
  network_config = local.network_config
  meta_data      = local.meta_data
  pool           = var.pool_name
}

# Create the machine
resource "libvirt_domain" "domain" {
  name   = "${local.identifier}"
  memory = var.memory
  vcpu   = var.cpus
  qemu_agent = true

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id = var.network_id
    hostname = var.hostname
    wait_for_lease = true
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
    volume_id = libvirt_volume.volume_qcow2.id
  }
}

output "ip_address" {
  description = "The IP address of the vm."
  value = libvirt_domain.domain.network_interface.0.addresses[0]
}
