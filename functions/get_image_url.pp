# Returns the URL of the cloud image for the specified platform.
#
# @param platform The platform string describing the image OS to
#   download. This will obtain the latest released version of
#   the image. To get a specific version, specify the
#   *image_url_params.image_version* as well.
# @param image_url_params Additional parameters for constructing
#   a specific historical or pre-release image URL, or bypassing
#   the URL construction process entirely. (See
#   Kvm_automation_tooling::Image_url_params for details.)
function kvm_automation_tooling::get_image_url(
  Kvm_automation_tooling::Allowed_platforms $platform,
  Optional[Kvm_automation_tooling::Image_url_params]
    $image_url_params = {},
) {
  $image_url_override = $image_url_params['image_url_override']
  if $image_url_override =~ NotUndef {
    log::warn(@("EOS"/L))
      kvm_automation_tooling::get_image_url() using provided \
      'image_url_override' ${image_url_override}
      |- EOS
    return $image_url_override
  }

  $platform_elements = $platform.split('-')
  $os_name = $platform_elements[0]
  $os_version = $platform_elements[1]
  $os_arch = $platform_elements[2]
  $image_version = $image_url_params['image_version']
  $image_servers = {
    'ubuntu' => 'https://cloud-images.ubuntu.com',
    'debian' => 'https://cloud.debian.org',
  }

  case $os_name {
    # Almalinux
    # Ex:
    # Current (9, 9.5 is latest minor):
    # Note: these four links all ultimately point to the same image,
    # I believe, and there aren't other dated (2024mmdd) images
    # available.
    # https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
    # https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.5-20241120.x86_64.qcow2
    # These are the same, just explicitly from the 9.5 subdir...
    # https://repo.almalinux.org/almalinux/9.5/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
    # https://repo.almalinux.org/almalinux/9.5/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.5-20241120.x86_64.qcow2
    #
    # Historical (note different base vault.almalinux.org...):
    # https://vault.almalinux.org/9.4/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
    # https://vault.almalinux.org/9.4/cloud/x86_64/images/AlmaLinux-9-GenericCloud-9.4-20240507.x86_64.qcow2
    #
    # Almalinux, unlike Debian, appears to only keep the last
    # historical image of each minor version.
    #
    # Also, frustratingly, a current 'daily' version like 9.5-20241120
    # which is the latest almalinux-9 image as of today, does not have
    # a corresponding link in the vault, unlike a historical
    # 9.4-20240507 image, so I can't make the assumption that any
    # version of the format x.y-YYYYMMDD is available in the vault...
    #
    # Pre-release:
    # Pre-release images are also in vault.alamlinux.org, but it's not
    # clear to me yet if there are 9.6-beta or 10.0-beta generic cloud
    # images with cloud-init available for use.

    # Rocky
    # Ex:
    # Note: like alma, these four links all ultimately point to the
    # same image, I believe, and there aren't other dated (2024mmdd)
    # images available.
    # https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
    # https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base-9.5-20241118.0.x86_64.qcow2
    # https://dl.rockylinux.org/pub/rocky/9.5/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
    # https://dl.rockylinux.org/pub/rocky/9.5/images/x86_64/Rocky-9-GenericCloud-Base-9.5-20241118.0.x86_64.qcow2
    #
    # Historical:
    # Like alma, they are in a separate vault under
    # dl.rockylinux.org/vault instead of /pub; however, they
    # apppear to keep additional dated images that are not the 9.y
    # latest.
    # https://dl.rockylinux.org/vault/rocky/9.4/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
    # https://dl.rockylinux.org/vault/rocky/9.4/images/x86_64/Rocky-9-GenericCloud-LVM-9.4-20240609.0.x86_64.qcow2
    # https://dl.rockylinux.org/vault/rocky/9.4/images/x86_64/Rocky-9-GenericCloud-Base-9.4-20240609.0.x86_64.qcow2
    #
    # Unlike alma, it looks like rocky does keep the latest daily
    # image in the vault, so 9.5-20241118.0, for example, can also
    # be found here:
    #
    # https://dl.rockylinux.org/vault/rocky/9.5/images/x86_64/Rocky-9-GenericCloud-Base-9.5-20241118.0.x86_64.qcow2
    #
    # Pre-release:
    # Not sure where these are or if they exist yet. I don't see
    # anything in their vault for 9.6 or 10.0.

    # Debian
    # Ex:
    # https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
    # https://cloud.debian.org/images/cloud/buster/20240703-1797/debian-10-generic-amd64-20240703-1797.qcow2
    # https://cloud.debian.org/images/cloud/buster/daily/20240703-1797/debian-10-generic-amd64-daily-20240703-1797.qcow2
    # These daily variations are available for released versions,
    # but are most important for pre-release images
    # (as of this writing, debian 13 is unreleased...):
    # https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2
    # https://cloud.debian.org/images/cloud/trixie/daily/20250430-2098/debian-13-generic-amd64-daily-20250430-2098.qcow2
    'debian': {
      $image_server = $image_servers[$os_name]
      $debian_version_name =
        kvm_automation_tooling::get_os_version_name('debian', $os_version)
      $base_url =
        "${image_server}/images/cloud/${debian_version_name}"
      $base_image_name = "debian-${os_version}-generic-${os_arch}"

      case $image_version {
        # Latest daily build.
        'daily-latest': {
          "${base_url}/daily/latest/${base_image_name}-daily.qcow2"
        }

        # Specific daily build.
        /^daily-(.+)$/: {
          "${base_url}/daily/${1}/${base_image_name}-${image_version}.qcow2"
        }

        # Specific historical build. (This would probably be the same
        # image if provided as "daily-${image_version}".)
        NotUndef: {
          "${base_url}/${image_version}/${base_image_name}-${image_version}.qcow2"
        }

        # If no image_version is given, default to latest released
        # version.
        default: {
          "${base_url}/latest/${base_image_name}.qcow2"
        }
      }
    }

    # Ubuntu
    # Ex:
    # https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
    # https://cloud-images.ubuntu.com/noble/20250425/noble-server-cloudimg-amd64.img
    # Don't have a current example beyond the daily builds.
    # Since openvox/perforce only supply repositories for LTS
    # versions, the case for what a pre-release image url will look
    # like is a little academic until 26.04 takes shape.
    #
    # It's 2025-04-30 as I write this, and Plucky (25.04 is out, and
    # 25.10 is not present on their cloud-images server).
    # Plucky has the same simple scheme as noble, at any rate.
    # https://cloud-images.ubuntu.com/plucky/current/plucky-server-cloudimg-amd64.img
    # https://cloud-images.ubuntu.com/plucky/20250429/plucky-server-cloudimg-amd64.img
    'ubuntu': {
      $image_server = $image_servers[$os_name]
      $ubuntu_version_name =
        kvm_automation_tooling::get_os_version_name('ubuntu', $os_version)
      $base_url = "${image_server}/${ubuntu_version_name}"
      $image_name = "${ubuntu_version_name}-server-cloudimg-${os_arch}"

      case $image_version {
        # Historical build.
        NotUndef: {
          "${base_url}/${image_version}/${image_name}.img"
        }

        # Latest released build.
        default: {
          "${base_url}/current/${image_name}.img"
        }
      }
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
