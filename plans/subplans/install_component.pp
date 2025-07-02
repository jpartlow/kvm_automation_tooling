# Installs a single openvox component on behalf of the caller.
#
# Uses puppet-openvox_bootstrap tasks.
#
# @param targets The targets to install the component on.
# @param package The name of the package to install.
# @param params The parameters for the openvox installation.
# @param defaults The default parameters for the openvox installation.
plan kvm_automation_tooling::subplans::install_component(
  TargetSpec $targets,
  String $package,
  Kvm_automation_tooling::Openvox_install_params $params,
  Kvm_automation_tooling::Openvox_install_params $defaults,
) {
  $install_params = kvm_automation_tooling::validate_openvox_version_parameters(
    $defaults + $params,
  )

  $released = $install_params['openvox_released']
  $version = $install_params['openvox_version']
  $collection = $install_params['openvox_collection']

  out::message("Installing ${package} ${version} (${collection})")

  if $released {
    run_task(
      'openvox_bootstrap::install',
      $targets,
      'package'    => $package,
      'version'    => $version,
      'collection' => $collection,
    )
  } else {
    $artifacts_url = $install_params['openvox_artifacts_url']
    $install_build_params = $artifacts_url =~ NotUndef ? {
      true    => {
        'artifacts_source' => $artifacts_url,
      },
      default => {},
    } + {
      'package' => $package,
      'version' => $version,
    }
    run_task(
      'openvox_bootstrap::install_build_artifact',
      $targets,
      $install_build_params
    )
  }

  $version_results = run_task('package', $targets, {
    'name'    => $package,
    'action'  => 'status',
  })

  return $version_results
}
