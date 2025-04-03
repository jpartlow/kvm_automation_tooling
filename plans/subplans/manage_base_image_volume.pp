# Ensure that the base image is downloaded for the given platform and
# imported into libvirt as a volume. Ensure that a libvirt pool for
# platform images based on this volume is created as well.
plan kvm_automation_tooling::subplans::manage_base_image_volume(
  String $platform,
  String $image_download_dir,
) {

  run_command("mkdir -p ${image_download_dir}", 'localhost')

  # Download and import base image.
  $base_image_url = kvm_automation_tooling::get_image_url($platform)
  $base_image_name = $base_image_url.split('/')[-1]
  $base_image_path = "${image_download_dir}/${base_image_name}"
  run_task('kvm_automation_tooling::download_image', 'localhost',
    'image_url'    => $base_image_url,
    'download_dir' => $image_download_dir,
  )
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
