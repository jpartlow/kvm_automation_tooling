# Install OpenVox Puppet agents and primary services on the cluster.
#
# This plan takes Bolt Target objects for parameters and is not
# intended to be called manually.
#
# The openvox_* install parameters are passed to tasks in the
# openvox_bootstrap module.
#
# Similarly to apply_prep, targets are marked with the puppet-agent
# feature, and facts are collected and added to the targets after
# agent installation.
#
# @param targets The targets to install the Puppet agent on.
# @param puppetserver_target The target to install the Puppet server on.
# @param puppetdb_target The target to install the PuppetDB on.
# @param postgresql_target The target to install PostgreSQL on.
# @param openvox_version The version of OpenVox to install, or
#   'latest' to install the latest released version in the given
#   openvox_collection.
# @param openvox_collection The OpenVox collection to install from.
#   This should match up with the openvox_version major (e.g. if
#   installing openvox 8.15.0, the collection should be openvox8) if
#   you are installing a release version. For pre-release versions, it
#   is ignored.
# @param openvox_released Whether to install a released version of
#   OpenVox from the given collection using OS package managers, or
#   to install a pre-release version from a build artifact.
# @param openvox_artifacts_url The URL to the OpenVox artifacts.
plan kvm_automation_tooling::install_openvox(
  Array[Target] $targets,
  Optional[Target] $puppetserver_target = undef,
  Optional[Target] $puppetdb_target = undef,
  Optional[Target] $postgresql_target = undef,
  Optional[Kvm_automation_tooling::Openvox_version]
    $openvox_version = 'latest',
  Optional[Kvm_automation_tooling::Openvox_collection]
    $openvox_collection = 'openvox8',
  Boolean $openvox_released = true,
  Optional[Stdlib::HTTPUrl] $openvox_artifacts_url = undef,
) {
  $install_params = kvm_automation_tooling::validate_openvox_version_parameters(
    'openvox_version'       => $openvox_version,
    'openvox_collection'    => $openvox_collection,
    'openvox_released'      => $openvox_released,
    'openvox_artifacts_url' => $openvox_artifacts_url,
  )

  if $openvox_released {
    run_task('openvox_bootstrap::install', $targets,
      'version'    => $install_params['openvox_version'],
      'collection' => $install_params['openvox_collection'],
    )
  } else {
    $_artifacts_url = $install_params['openvox_artifacts_url']
    $install_build_params = $_artifacts_url =~ NotUndef ? {
      true    => {
        'artifacts_source' => $_artifacts_url,
      },
      default => {},
    } + {
      'version' => $install_params['openvox_version'],
    }
    run_task(
      'openvox_bootstrap::install_build_artifact',
      $targets,
      $install_build_params
    )
  }

  # Mark each target as having the puppet-agent.
  $targets.each |$target| {
    set_feature($target, 'puppet-agent', true)
  }

  # Collect facts and add them to the targets.
  run_plan('facts', 'targets' => $targets)

  # TODO: Apply manifests to standup the server services.
  # Probably split this out as a separate install_openvox_services
  # plan, to call either from here or standup_cluster directly?
}
