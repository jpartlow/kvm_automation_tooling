locals {
  allowed_platforms = [
    "ubuntu-1804-amd64",
    "ubuntu-2004-amd64",
    "ubuntu-2204-amd64",
    "ubuntu-2404-amd64",
  ]

  platform_image_pool_path = "/var/lib/libvirt/images/${var.platform}"
  platform_pool_name = "${var.platform}.pool"

  platform_elements = split("-", var.platform)
  os_name = local.platform_elements[0]
  os_version = local.platform_elements[1]
  os_arch = local.platform_elements[2]

  ubuntu_version_names = {
    "1804" = "bionic",
    "2004" = "focal",
    "2204" = "jammy",
    "2404" = "noble",
  }
  ubuntu_version_name = lookup(local.ubuntu_version_names, local.os_version, "")
  image_servers = {
    "ubuntu" = "https://cloud-images.ubuntu.com",
  }
  image_server = lookup(local.image_servers, local.os_name, "")
  platform_source_image_names = {
    "ubuntu" = "${local.ubuntu_version_name}-server-cloudimg-${local.os_arch}",
  }
  platform_source_image_name = lookup(local.platform_source_image_names, local.os_name, "")
  platform_sources = {
    # Ex: https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
    "ubuntu" = "${local.image_server}/${local.ubuntu_version_name}/current/${local.platform_source_image_name}.img",
    # TODO: debian, rocky, suse, fedora, etc.
  }
  platform_source = lookup(local.platform_sources, local.os_name, "")

  ssh_public_key = file(var.ssh_public_key_path)
}
