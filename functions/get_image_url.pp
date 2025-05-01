# Returns the URL of the cloud image for the specified platform.
#
# # NOTES
#
# These are the structure of the URLs for the various platforms as of
# 2025-04-30:
#
# ## Almalinux
#
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
#
# ## Rocky
#
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
#
# ## Debian
#
# https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
# https://cloud.debian.org/images/cloud/buster/20240703-1797/debian-10-generic-amd64-20240703-1797.qcow2
# https://cloud.debian.org/images/cloud/buster/daily/20240703-1797/debian-10-generic-amd64-daily-20240703-1797.qcow2
# These daily variations are available for released versions,
# but are most important for pre-release images
# (as of this writing, debian 13 is unreleased...):
# https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2
# https://cloud.debian.org/images/cloud/trixie/daily/20250430-2098/debian-13-generic-amd64-daily-20250430-2098.qcow2
#
# ## Ubuntu
#
# https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
# https://cloud-images.ubuntu.com/noble/20250425/noble-server-cloudimg-amd64.img
# Don't have a current example beyond the daily builds.
# Since openvox/perforce only supply repositories for LTS
# versions, the case for what a pre-release image url will look
# like is a little academic until 26.04 takes shape.
#
# It's 2025-04-30 as I write this, and Plucky (25.04) is out, and
# 25.10 is not present on their cloud-images server.
# Plucky has the same simple scheme as noble, at any rate.
# https://cloud-images.ubuntu.com/plucky/current/plucky-server-cloudimg-amd64.img
# https://cloud-images.ubuntu.com/plucky/20250429/plucky-server-cloudimg-amd64.img
#
# # Parameters
#
# @param os_spec The platform specification describing the image OS to
#   download. This will obtain the latest released version of the image.
#   To get a specific version, ensure that *os_spec.image_version* is
#   set as well.
#
#   To bypass url generation entirely, set
#   *os_spec.image_url_override* to the complete URL of the desired
#   image.
function kvm_automation_tooling::get_image_url(
  Kvm_automation_tooling::Os_spec $os_spec,
) {
  $image_url_override = $os_spec['image_url_override']
  if $image_url_override =~ NotUndef {
    log::warn(@("EOS"/L))
      kvm_automation_tooling::get_image_url() using provided \
      'image_url_override' ${image_url_override}
      |- EOS
    return $image_url_override
  }

  $os_name = $os_spec['name']
  $os_version = $os_spec['version']
  $os_arch =
    kvm_automation_tooling::get_normalized_os_arch($os_name, $os_spec['arch'])
  $image_version = $os_spec['image_version']
  $image_servers = {
    'ubuntu' => 'https://cloud-images.ubuntu.com',
    'debian' => 'https://cloud.debian.org',
  }
  $image_server = $image_servers[$os_name]
  $codename =
    kvm_automation_tooling::translate_os_version_codename($os_name, $os_version)

  case $os_name {
    'debian': {
      $base_url =
        "${image_server}/images/cloud/${codename}"
      $base_image_name = "debian-${os_version}-generic-${os_arch}"

      case $image_version {
        # Latest daily build.
        # Ex:
        # https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2
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
        # Ex:
        # https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2
        default: {
          "${base_url}/latest/${base_image_name}.qcow2"
        }
      }
    }

    'ubuntu': {
      $base_url = "${image_server}/${codename}"
      $image_name = "${codename}-server-cloudimg-${os_arch}"

      case $image_version {
        # Historical build.
        # Ex:
        # https://cloud-images.ubuntu.com/noble/20250425/noble-server-cloudimg-amd64.img
        NotUndef: {
          "${base_url}/${image_version}/${image_name}.img"
        }

        # Latest released build.
        # Ex:
        # https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
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
