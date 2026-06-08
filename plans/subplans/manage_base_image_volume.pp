# Ensure that the base image is downloaded for the given platform and
# imported into libvirt as a volume. Ensure that a libvirt pool for
# platform images based on this volume is created as well.
#
# @param os_spec The operating system specification for the base
#   image.
# @param image_download_dir The directory where the base image will be
#   downloaded and stored.
# @param in_gha Whether this is running in GitHub Actions.
#   Controls whether to run virt-customize workarounds for platforms
#   having issues running within in gha. Usually determined
#   automatically.
plan kvm_automation_tooling::subplans::manage_base_image_volume(
  Kvm_automation_tooling::Os_spec $os_spec,
  String $image_download_dir,
  Boolean $in_gha = (system::env('GITHUB_ACTIONS') == 'true'),
) {
  $platform = kvm_automation_tooling::platform($os_spec)

  run_command("mkdir -p ${image_download_dir}", 'localhost')

  # Download and import base image.
  $base_image_url = kvm_automation_tooling::get_image_url($os_spec)
  $base_image_name = $base_image_url.split('/')[-1]
  $base_image_path = "${image_download_dir}/${base_image_name}"
  run_task('kvm_automation_tooling::download_image', 'localhost',
    'image_url'    => $base_image_url,
    'download_dir' => $image_download_dir,
  )

  if $in_gha {
    $vc_systemd_conf_d = '/etc/systemd/system.conf.d'
    $vc_device_timeout_conf = "${vc_systemd_conf_d}/99-device-timeout.conf"
    $virt_customizations_table = {
      # In GHA x86_64 runners, ubuntu 26.04 arm images are hitting
      # timeouts waiting for the boot/uefi disk devices to be available,
      # so this boots the systemd device timeout from the default of 90s
      # to 300s.
      'ubuntu-2604-arm64' => [
        "--mkdir '${vc_systemd_conf_d}'",
        "--write '${vc_device_timeout_conf}:[Manager]'",
        "--append '${vc_device_timeout_conf}:DefaultDeviceTimeoutSec=300'",
      ],
    }
    $virt_customizations = $virt_customizations_table[$platform]
    if $virt_customizations !~ Undef {
      $command = "virt-customize -a ${base_image_path} --no-network ${virt_customizations.join(' ')}"
      run_command($command, 'localhost',
        '_run_as' => 'root',
        # For debugging virt-customize (this is verbose).
#        '_env_vars' => {
#          'LIBGUESTFS_DEBUG' => 1,
#          'LIBGUESTFS_TRACE' => 1,
#        },
      )
    }
  }

  run_task('kvm_automation_tooling::import_libvirt_volume', 'localhost',
    'image_path'  => $base_image_path,
    'volume_name' => $base_image_name,
  )

  # Ensure platform image pool exists.
  $pool_name = "${platform}.pool"
  # TODO: This should probably just be called 'pool_dir'. Or I should
  #       elliminate the distinction between the two and drop '.pool'.
  $pool_path = $platform
  run_task('kvm_automation_tooling::create_libvirt_image_pool', 'localhost',
    'name' => $pool_name,
    'path' => $pool_path,
  )

  $result = {
    'platform'         => $platform,
    'base_image_url'   => $base_image_url,
    'base_volume_name' => $base_image_name,
    'pool_name'        => $pool_name,
    'pool_path'        => $pool_path,
  }
  return $result
}
