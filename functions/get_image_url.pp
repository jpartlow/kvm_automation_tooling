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
  }

  case $os_name {
    # Ex: https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
    'ubuntu': {
      $image_server = $image_servers[$os_name]
      $ubuntu_version_name = kvm_automation_tooling::get_ubuntu_version_name($os_version)
      $platform_source_image_name = "${ubuntu_version_name}-server-cloudimg-${os_arch}"

      "${image_server}/${ubuntu_version_name}/current/${platform_source_image_name}.img"
    }

    # TODO: debian, rocky, suse, fedora, etc.
    default: {
      fail(@("ERR"/L))
        The kvm_automation_tooling::get_image_url() function does not yet support platform: ${platform}
        (The Kvm_automation_tooling::Allowed_platforms enumeration is out of sync.)")
        | - ERR
    }
  }
}
