# Transform the PlanResult ResultSet of package version hashes
# returned by the kvm_automation_tooling::subplans::install_component
# plan into a Hash of host names to package version hashes.
#
# @param results The PlanResult containing the results of the
#   kvm_automation_tooling::subplans::install_component plan.
# @param initial The initial Hash to reduce the results into.
function kvm_automation_tooling::transform_openvox_host_version_results(
  String $package,
  PlanResult $results,
  Hash $initial = {},
) >> Hash[String, Hash[String, String]] {
  $results.reduce($initial) |$m, $result| {
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
