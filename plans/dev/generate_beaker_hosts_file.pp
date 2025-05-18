# Convert the puppet inventory group into a hosts.yaml file for
# use with Beaker.
#
# @param hosts The hosts to include in the hosts.yaml file.
# @param hosts_yaml An absolute path of the hosts file to generate.
plan kvm_automation_tooling::dev::generate_beaker_hosts_file(
  TargetSpec $hosts = 'all',
  String[1] $hosts_yaml = '/tmp/hosts.yaml',
) {
  $host_targets = get_targets($hosts)
  # This has the side effect of setting a 'platform' variable on each
  # agent target, if not already set.
  run_plan('kvm_automation_tooling::subplans::lookup_platform', 'targets' => $host_targets)

  $host_targets.each |$t| {
    $platform = $t.vars['platform']
    $os_family = dig($t.facts, 'os', 'family')
    # beaker::platform::PLATFORMS does not currently contain almalinix
    # or rocky:
    # https://github.com/voxpupuli/beaker/blob/master/lib/beaker/platform.rb#L6
    # So need to switch those to 'el' for the present.
    case $os_family {
      'redhat': {
        $os = downcase(dig($t.facts, 'os', 'name'))
        $beaker_platform = regsubst($platform, $os, 'el')
      }
      default: {
        $beaker_platform = $platform
      }
    }
    $t.set_var('beaker_platform', $beaker_platform)
  }

  $hosts_yaml_content = epp('kvm_automation_tooling/beaker-hosts.yaml.epp', {
    'agents' => $host_targets,
  })
  file::write($hosts_yaml, $hosts_yaml_content)
}
