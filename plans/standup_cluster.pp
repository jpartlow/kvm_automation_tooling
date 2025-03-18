# Standup one cluster of KVM virtual machines for a particular OS Puppet
# architecture.
#
# Makes use of terraform under the hood for vm initialization.
#
# @param cluster_name This is combined with *architecture*, *os*,
#   *os_version*, *os_arch* to obtain a reasonably unique id for the
#   cluster. The *cluster_name* allows you to stand up more than one
#   cluster of the same architecture and platform, for example.
# @param architecture The Puppet services architecture of the cluster
#   (see docs/ARCHITECTURE.md).
# @param os The base operating system of the cluster.
# @param os_version The version of the base operating system of the
#   cluster.
# @param os_arch The chip architecture of the base operating system of
#   the cluster.
# @param network_addresses The network address range to use for the
#   cluster. This should be a /24 CIDR block.
# @param agents The number of Puppet agent vms to stand up in the
#   cluster.
# @param primary_cpus The number of CPUs to allocate to the primary vm.
# @param primary_mem_mb The amount of memory in MB to allocate to the
#   primary vm.
# @param primary_disk_gb The amount of disk space in GB to allocate to
#   the primary vm.
# @param agent_cpus The number of CPUs to allocate to each agent vm.
# @param agent_mem_mb The amount of memory in MB to allocate to each
#   agent vm.
# @param agent_disk_gb The amount of disk space in GB to allocate to
#   each agent vm.
# @param image_download_dir The directory where base os images are
#   downloaded to. This should be an absolute path.
# @param terraform_state_dir The directory where terraform state files,
#   and the Bolt inventory files for the cluster instances, are stored.
#   This should be an absolute or Puppet module relative path that the
#   find_files function can locate.
# @param user The login user to create on the vms for ssh access.
#   Defaults to the *USER* env variable. If set to something else, this
#   must match up with either your local ssh config, or an override in
#   the Bolt inventory file.
# @param ssh_public_key_path The path to the public key to add to the
#   guest's login user ~/.ssh/authorized_keys, allowing ssh access.
# @param user_password The password to set for the login user on the vms.
#   This is optional and should only be used for debugging.
plan kvm_automation_tooling::standup_cluster(
  String $cluster_name,
  Kvm_automation_tooling::Architecture $architecture = 'singular',
  Kvm_automation_tooling::Operating_system $os,
  Kvm_automation_tooling::Version $os_version,
  Kvm_automation_tooling::Os_arch $os_arch,
  Stdlib::Ip::Address::V4::CIDR $network_addresses,
  Integer $agents = 1,
  Integer $primary_cpus = 4,
  Integer $primary_mem_mb = 8192,
  Integer $primary_disk_gb = 20,
  Integer $agent_cpus = 1,
  Integer $agent_mem_mb = 512,
  Integer $agent_disk_gb = 10,
  String $image_download_dir = "${system::env('HOME')}/images",
  String $terraform_state_dir = 'kvm_automation_tooling/../terraform/instances',
  String $user = system::env('USER'),
  String $ssh_public_key_path = "${system::env('HOME')}/.ssh/id_rsa.pub",
  Optional[Sensitive[String]] $user_password = undef,
) {
  $terraform_dir = './terraform'
  $platform = kvm_automation_tooling::platform($os, $os_version, $os_arch)
  $cluster_id = "${cluster_name}-${architecture}-${platform}"
  $domain_name = "${cluster_id}.vm"
  $primary_hostname = "${cluster_id}-primary"
  $agent_hostnames = $agents.map |$i| { "${cluster_id}-agent-${i}" }
  $_terraform_state_dir = find_file($terraform_state_dir)
  $tfvars_file = "${_terraform_state_dir}/${cluster_id}.tfvars.json"
  $tfstate_file_name = "${cluster_id}.tfstate"
  $tfstate_file = "${_terraform_state_dir}/${tfstate_file_name}"
  $inventory_file = "${_terraform_state_dir}/inventory.${cluster_id}.yaml"

  # Ensure base image volume is present and a platform image pool exists.
  $image_results = run_plan('kvm_automation_tooling::subplans::manage_base_image_volume',
    'platform' => $platform,
    'image_download_dir' => $image_download_dir,
  )

  # Write cluster specific tfvars.json file to a separate directory to
  # keep different cluster instances separated.
  file::write($tfvars_file, stdlib::to_json({
    # TODO: this list was generated by copilot and needs to be reviewed.
    'cluster_id'          => $cluster_id,
    'base_volume_name'    => $image_results['base_volume_name'],
    'pool_name'           => $image_results['pool_name'],
    'network_addresses'   => $network_addresses,
    'domain_name'         => $domain_name,
    'user_name'           => $user,
    'ssh_public_key_path' => $ssh_public_key_path,
    'user_password'       => $user_password.unwrap,
    'agent_count'         => $agents,
    'primary_cpus'        => $primary_cpus,
    'primary_mem_mb'      => $primary_mem_mb,
    'primary_disk_gb'     => $primary_disk_gb,
    'agent_cpus'          => $agent_cpus,
    'agent_mem_mb'        => $agent_mem_mb,
    'agent_disk_gb'       => $agent_disk_gb,
  }))

  # Ensure terraform dependencies are installed.
  run_task('terraform::initialize', 'localhost', 'dir' => $terraform_dir)

  # Terraform apply.
  $apply_result = run_plan('terraform::apply',
    'dir'      => $terraform_dir,
    'var_file' => $tfvars_file,
    'state'    => $tfstate_file,
    'return_output' => true,
  )
  out::message($apply_result)

  # Generate an inventory file for the cluster.
  file::write($inventory_file, epp('kvm_automation_tooling/inventory.yaml.epp', {
    'tfstate_dir'       => $_terraform_state_dir,
    'tfstate_file_name' => $tfstate_file_name,
    'ssh_user_name'     => $user,
    'domain_name'       => $domain_name,
  }))

  $primary_target = kvm_automation_tooling::resolve_terraform_targets($inventory_file, 'primary')[0]
  out::message("Primary target: ${primary_target}")

  $agent_targets = kvm_automation_tooling::resolve_terraform_targets($inventory_file, 'agent')
  out::message("Agent targets: ${agent_targets}")

  $all_targets = [$primary_target] + $agent_targets

  run_plan('kvm_automation_tooling::subplans::install_puppet',
    'targets' => $all_targets,
    'puppetserver_target' => $primary_target,
    'puppetdb_target' => $primary_target,
    'postgresql_target' => $primary_target,
  )
}
