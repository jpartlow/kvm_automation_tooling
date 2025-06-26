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

  $installations = [
    [$all_targets, 'openvox-agent', $openvox_agent_params],
    [$server_targets, 'openvox-server', $openvox_server_params],
    [$db_targets, 'openvoxdb', $openvox_db_params],
    [$db_termini_targets, 'openvoxdb-termini', $openvox_db_params],
  ]
  $version_map = $installations.reduce({}) |$map, $i| {
    $targets = $i[0]
    $package = $i[1]
    $params  = $i[2]

    if $targets.empty() { next($map) }

    $install_params = kvm_automation_tooling::validate_openvox_version_parameters(
      $install_defaults + $params,
    )

    out::message("Installing ${package}")

    if $install_params['openvox_released'] {
      run_task(
        'openvox_bootstrap::install',
        $targets,
        'package'    => $package,
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
        'package' => $package,
        'version' => $install_params['openvox_version'],
      }
      run_task(
        'openvox_bootstrap::install_build_artifact',
        $targets,
        $install_build_params
      )
    }

    if $package == 'openvox-agent' {
      # Mark each target as having the puppet-agent.
      $targets.each |$target| {
        set_feature($target, 'puppet-agent', true)
      }

      # Collect facts and add them to the targets.
      run_plan('facts', 'targets' => $targets)
    }

    $version_results = run_task('package', $targets, {
      'name'    => $package,
      'action'  => 'status',
    })

    $version_results.reduce($map) |$m, $result| {
      $host = $result.target().name()
      $package_version = (empty($result['version'])) ? {
        true     => 'unknown',
        default  => $result['version'],
      }
      $host_versions = $m[$host] =~ NotUndef ? {
        true    => $m[$host],
        default => {},
      }

      $m + {
        $host => $host_versions + {
          $package => $package_version,
        }
      }
    }
  }

  return($version_map)
}
