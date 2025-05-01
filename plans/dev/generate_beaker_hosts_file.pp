# Convert the puppet inventory group into a hosts.yaml file for
# use with Beaker.
#
# @param hosts The hosts to include in the hosts.yaml file.
# @param hosts_yaml An absolute path of the hosts file to generate.
plan kvm_automation_tooling::dev::generate_beaker_hosts_file(
  TargetSpec $hosts = 'puppet',
  String[1] $hosts_yaml = '/tmp/hosts.yaml',
) {
  $host_targets = get_targets($hosts)
  # This has the side effect of setting a 'platform' variable on each agent target.
  run_plan('kvm_automation_tooling::subplans::lookup_platform', 'targets' => $host_targets)
  $hosts_yaml_content = epp('kvm_automation_tooling/beaker-hosts.yaml.epp', {
    'agents' => $host_targets,
  })
  file::write($hosts_yaml, $hosts_yaml_content)
}
