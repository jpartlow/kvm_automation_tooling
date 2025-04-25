# Returns the URL of the cloud image for the specified platform.
function kvm_automation_tooling::get_image_url(
  Kvm_automation_tooling::Allowed_platforms $platform,
) {
  $platform_elements = $platform.split('-')
  $os_name = $platform_elements[0]
  $os_version = $platform_elements[1]
  $os_arch = $platform_elements[2]
  $image_servers = {
    'ubuntu' => 'https://cloud-images.ubuntu.com',
    'debian' => 'https://cloud.debian.org',
  }

  case $os_name {
    # Ex:
    # https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
    'debian': {
      $image_server = $image_servers[$os_name]
      $debian_version_name = kvm_automation_tooling::get_os_version_name('debian', $os_version)
      $platform_source_image_name = "debian-${os_version}-generic-amd64"

      "${image_server}/images/cloud/${debian_version_name}/latest/${platform_source_image_name}.qcow2"
    }

    # Ex: https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
    'ubuntu': {
      $image_server = $image_servers[$os_name]
      $ubuntu_version_name = kvm_automation_tooling::get_os_version_name('ubuntu', $os_version)
      $platform_source_image_name = "${ubuntu_version_name}-server-cloudimg-${os_arch}"

      "${image_server}/${ubuntu_version_name}/current/${platform_source_image_name}.img"
    }

    # TODO: rocky, suse, fedora, etc.
    default: {
      fail(@("ERR"/L))
        The kvm_automation_tooling::get_image_url() function does not \
        yet support platform: ${platform} \
        (The Kvm_automation_tooling::Allowed_platforms enumeration \
        is out of sync.)")
        | - ERR
    }
  }
}
