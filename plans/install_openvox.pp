# Install OpenVox Puppet agents and primary services on the cluster
# without any attempts at configuration.
#
# The openvox_* install parameters are passed to tasks in the
# openvox_bootstrap module.
#
# Similarly to apply_prep, targets are marked with the puppet-agent
# feature, and facts are collected and added to the targets after
# agent installation.
#
# NOTE: The agent will be installed on server and db targets as well.
#
# NOTE: The openvoxdb-termini package will be installed on all server
# targets by default. Set $install_termini to false to skip this.
#
# @param openvox_agent_targets The targets to install the OpenVox
#   Puppet agent on.
# @param openvox_server_targets The target to install the OpenVox
#   Puppet server on.
# @param openvox_db_targets The target to install the OpenVox PuppetDB
#   on.
# @param openvox_agent_params The set of
#   Kvm_automation_tooling::Openvox_install_params defining source
#   and version for the openvox-agent package to install on all
#   $targets.
# @param openvox_server_params The install params for the
#   openvox-server package to install on the $openvox_server_targets.
# @param openvox_db_params The install params for the
#   openvoxdb package to install on the $openvox_db_targets.
# @param install_defaults The default parameters to include
#   in each of the $openvox_*_params hashes.
# @param install_termini Whether to install the openvoxdb-termini
#   package on the $openvox_server_targets. The openvoxdb-termini
#   package contains Puppet terminus classes, functions and faces for
#   interacting with openvoxdb and is typically used to configure
#   openvox-server for communicating with openvoxdb.
plan kvm_automation_tooling::install_openvox(
  TargetSpec $openvox_agent_targets,
  TargetSpec $openvox_server_targets = [],
  TargetSpec $openvox_db_targets = [],
  Kvm_automation_tooling::Openvox_install_params
    $openvox_agent_params = {},
  Kvm_automation_tooling::Openvox_install_params
    $openvox_server_params = {},
  Kvm_automation_tooling::Openvox_install_params
    $openvox_db_params = {},
  Kvm_automation_tooling::Openvox_install_params
    $install_defaults = {
      'openvox_version'       => 'latest',
      'openvox_collection'    => 'openvox8',
      'openvox_released'      => true,
    },
  Boolean $install_termini = true,
) {
  # Resolve targets in case we were given hostname or inventory group
  # name references instead of Target objects.
  $agent_targets  = get_targets($openvox_agent_targets)
  $server_targets = get_targets($openvox_server_targets)
  $db_targets     = get_targets($openvox_db_targets)
  $db_termini_targets = $install_termini ? {
    true    => $server_targets,
    default => [],
  }
  $all_targets    = [$agent_targets, $server_targets, $db_targets].flatten().unique()

  $agent_version_results = run_plan(
    'kvm_automation_tooling::subplans::install_component',
    'targets'  => $all_targets,
    'package'  => 'openvox-agent',
    'params'   => $openvox_agent_params,
    'defaults' => $install_defaults,
  )
  $agent_version_map = kvm_automation_tooling::transform_openvox_host_version_results(
    'openvox-agent',
    $agent_version_results,
  )

  # Mark each target as having the puppet-agent.
  $all_targets.each |$target| {
    set_feature($target, 'puppet-agent', true)
  }

  # Collect facts and add them to the targets.
  run_plan('facts', 'targets' => $all_targets)

  # Install pre-requisite packages for the openvox-server
  # and openvoxdb packages if required (pre-release packages).
  [
    [$server_targets, 'openvox-server', $openvox_server_params],
    [($db_targets - $server_targets), 'openvoxdb', $openvox_db_params],
  ].each |$i| {
    $targets = $i[0]
    $package = $i[1]
    $params  = $i[2]

    if $targets.empty() { next() }

    run_plan(
      'kvm_automation_tooling::subplans::install_server_prerequisites',
      'targets'  => $targets,
      'package'  => $package,
      'params'   => $params,
      'defaults' => $install_defaults,
    )
  }

  $server_installations = [
    [$server_targets, 'openvox-server', $openvox_server_params],
    [$db_targets, 'openvoxdb', $openvox_db_params],
    [$db_termini_targets, 'openvoxdb-termini', $openvox_db_params],
  ]
  $version_map = $server_installations.reduce($agent_version_map) |$map, $i| {
    $targets = $i[0]
    $package = $i[1]
    $params  = $i[2]

    if $targets.empty() { next($map) }

    $version_results = run_plan(
      'kvm_automation_tooling::subplans::install_component',
      'targets'  => $targets,
      'package'  => $package,
      'params'   => $params,
      'defaults' => $install_defaults,
    )

    kvm_automation_tooling::transform_openvox_host_version_results(
      $package,
      $version_results,
      $map,
    )
  }

  return($version_map)
}
