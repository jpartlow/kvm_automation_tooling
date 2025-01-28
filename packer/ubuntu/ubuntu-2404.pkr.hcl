packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu-2404" {
  iso_url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  iso_checksum     = "file:https://cloud-images.ubuntu.com/noble/current/SHA256SUMS"
  format           = "qcow2"
  disk_image       = true
  use_backing_file = true
  ssh_username     = "root"
}

build {
  sources = ["source.qemu.ubuntu-2404"]
}
