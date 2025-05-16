# Standup one cluster of KVM virtual machines based on a given
# Kvm_automation_tooling::Vm_spec structure.
#
# Makes use of terraform under the hood for vm initialization.
#
# @param cluster_id This should be a short, unique string per cluster.
#   It must obey the character constraints for hostname as it is
#   combined with the vm spec role and count to form unique hostnames
#   for each vm in the cluster..
# @param os The default operating system of the cluster.
#   NOTE: os, os_version and os_arch are only 'optional' in the sense
#   that they can be specified specifically in the vm spec hashes. But
#   if not provided, each vm spec hash must have them set.
#   Additionally, if one is set, all three must be set to define the
#   platform.
# @param os_version The version of the default operating system of the
#   cluster.
# @param os_arch The chip architecture of the default operating system
#   of the cluster.
# @param image_version Specific image version to download. If not set,
#   the latest released version is downloaded. (See
#   [Kvm_automation_tooling::Os_spec](./types/os_spec.pp) for
#   details.)
# @param image_url_override Complete URL pointing to the specific
#   image to download. (See
#   [Kvm_automation_tooling::Os_spec](./types/os_spec.pp) for
#   details.)
# @param vms An array of VM specifications for the cluster. Example:
#     [
#       {
#         'role' => 'primary',
#         'cpus' => 8,
#         'mem_mb'  => 8192,
#         'disk_gb' => 20,
#       },
#       {
#         'role'  => 'agent',
#         'count' => 3,
#       },
#     ]
#   The os, os_version and os_arch keys are provided by the top
#   level plan parameters unless overridden in a specific spec hash.
#   The count key is optional and defaults to 1.
#   (See the Kvm_automation_tooling::Vm_spec type for details.)
# @param network_addresses The network address range to use for the
#   cluster. This should be a /24 CIDR block.
# @param domain_name The domain name to use for the cluster. This is
#   appended to the hostnames of the VMs in the cluster, and will
#   resolve locally within the cluster.
# @param architecture The Puppet services architecture of the cluster
#   (see docs/ARCHITECTURE.md). (Currently unused.)
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
# @param ssh_private_key_path The path to the private key to use for
#   ssh access to the vms. (This will be set in the generated inventory
#   file.)
# @param setup_cluster_ssh Whether to setup ssh access between
#   the VMs in the cluster. This is done by creating a new ssh keypair
#   on controller VMs (any vm with the role of 'primary' or 'runner'),
#   and adding the public key to the login account of all other vms in
#   the cluster.
#   See the kvm_automation_tooling::subplans::setup_cluster_ssh
#   plan for details.
# @param setup_cluster_root_ssh Whether to allow root ssh
#   access between controller and destination VMs in the cluster. Only
#   applies if *setup_cluster_ssh* is true.
# @param host_root_access Whether to allow root ssh access from the
#   host machine to all VMs in the cluster. The *ssh_public_key_path*
#   key is propogated to all *user* accounts on the generated VMs
#   automatically as part of cloud-init during the Terraform. Without
#   this, Bolt wouldn't be able to communicate with the VMs as *user*.
#   This flag determines whether to additionally add this public key
#   to the root accounts.
# @param user_password The password to set for the login user on the
#   vms. This is optional and should only be used for debugging.
# @param install_openvox Whether to install openvox Puppet(TM) on the
#   vms in the cluster.
# @param install_openvox_params A hash of parameters to pass to the
#   kvm_automation_tooling::subplans::install_openvox plan if
#   installing something other than the latest agent package from
#   the latest collection. See the subplan for parameter details.
plan kvm_automation_tooling::standup_cluster(
  Pattern['[[a-z][A-Z][0-9]-]+'] $cluster_id,
  Optional[Kvm_automation_tooling::Operating_system] $os = undef,
  Optional[Kvm_automation_tooling::Version] $os_version = undef,
  Optional[Kvm_automation_tooling::Os_arch] $os_arch = undef,
  Optional[String[1]] $image_version = undef,
  Optional[Stdlib::HTTPUrl] $image_url_override = undef,
  Array[Kvm_automation_tooling::Vm_spec,1] $vms,
  Stdlib::Ip::Address::V4::CIDR $network_addresses,
  String $domain_name = 'vm',
  Kvm_automation_tooling::Architecture $architecture = 'singular',
  String $image_download_dir = "${system::env('HOME')}/images",
  String $terraform_state_dir = 'kvm_automation_tooling/../terraform/instances',
  String $user = system::env('USER'),
  String $ssh_public_key_path = "${system::env('HOME')}/.ssh/id_rsa.pub",
  String $ssh_private_key_path = regsubst($ssh_public_key_path, '(.*).pub', '\\1'),
  Boolean $setup_cluster_ssh = true,
  Boolean $setup_cluster_root_ssh = false,
  Boolean $host_root_access = false,
  Optional[String] $user_password = undef,
  Boolean $install_openvox = true,
  Kvm_automation_tooling::Openvox_install_params
  $install_openvox_params = {},
) {
  $terraform_dir = './terraform'

  # validate os parameters
  if [$os, $os_version, $os_arch].all |$i| { $i =~ Undef } {
    if $vms.any |$vm_spec| { $vm_spec['os'] =~ Undef } {
      fail('The os, os_version and os_arch parameters must be set if not set in the vm spec hashes.')
    }
  } elsif [$os, $os_version, $os_arch].any |$i| { $i =~ Undef } {
    fail('The os, os_version and os_arch parameters must all be set if one is set.')
  }
  # Not going to worry just yet about partially defined os params inside
  # the vm spec hashes...

  $roles = $vms.map |$s| { $s['role'] }.unique()
  $vm_specs = $vms.map |$vm_spec| {
    kvm_automation_tooling::fill_vm_spec($vm_spec, {
      'role' => 'defaults',
      'os'   => {
        'name'    => $os,
        'version' => $os_version,
        'arch'    => $os_arch,
        'image_version'      => $image_version,
        'image_url_override' => $image_url_override,
      },
    })
  }
  $os_specs = $vm_specs.map |$vm_spec| { $vm_spec['os'] }.unique()

  $cluster_platform = kvm_automation_tooling::platform({
    'name'    => $os,
    'version' => $os_version,
    'arch'    => $os_arch,
  })

  $_terraform_state_dir = find_file($terraform_state_dir)
  $tfvars_file = "${_terraform_state_dir}/${cluster_id}.tfvars.json"
  $tfstate_file_name = "${cluster_id}.tfstate"
  $tfstate_file = "${_terraform_state_dir}/${tfstate_file_name}"
  $inventory_file = "${_terraform_state_dir}/inventory.${cluster_id}.yaml"

  # Ensure base image volumes are present and a platform image pools
  # exist.
  $image_results = parallelize($os_specs) |$os_spec| {
    run_plan(
      'kvm_automation_tooling::subplans::manage_base_image_volume',
      'os_spec' => $os_spec,
      'image_download_dir' => $image_download_dir,
    )
  }

  # Write cluster specific tfvars.json file to a separate directory to
  # keep different cluster instances separated.
  file::write($tfvars_file, stdlib::to_json({
    'cluster_id'          => $cluster_id,
    'network_addresses'   => $network_addresses,
    'domain_name'         => $domain_name,
    'user_name'           => $user,
    'ssh_public_key_path' => $ssh_public_key_path,
    'user_password'       => $user_password,
    'vm_specs'            => kvm_automation_tooling::generate_terraform_vm_spec_set($cluster_id, $vm_specs, $image_results),
  }))

  # Ensure terraform dependencies are installed.
  run_task('terraform::initialize', 'localhost', 'dir' => $terraform_dir)

  # Terraform apply until the output indicates we have valid ipv4
  # addreses for all hosts.
  ctrl::do_until(limit => 10, interval => 5) || {
    $apply_result = run_plan('terraform::apply',
      'dir'      => $terraform_dir,
      'var_file' => $tfvars_file,
      'state'    => $tfstate_file,
      'return_output' => true,
    )
    kvm_automation_tooling::validate_vm_ip_addresses($apply_result)
  }

  # Generate an inventory file for the cluster.
  file::write($inventory_file, epp('kvm_automation_tooling/inventory.yaml.epp', {
    'tfstate_dir'       => $_terraform_state_dir,
    'tfstate_file_name' => $tfstate_file_name,
    'ssh_user_name'     => $user,
    'ssh_key_file'      => $ssh_private_key_path,
    'domain_name'       => $domain_name,
    'roles'             => $roles,
  }))

  $target_map = $roles.reduce({}) |$map, $role| {
    $targets = kvm_automation_tooling::resolve_terraform_targets($inventory_file, $role)
    out::message("${capitalize($role)} targets: ${stdlib::to_json_pretty($targets)}")
    $map + { $role => $targets }
  }

  $all_targets = $target_map.values().flatten()

  wait_until_available($all_targets)

  if $setup_cluster_ssh {
    $controllers = $target_map.reduce([]) |$acc, $entry| {
      $role = $entry[0]
      $targets = $entry[1]
      if ['primary', 'runner'].any |$i| { $role == $i } {
        $acc + $targets
      } else {
        $acc
      }
    }
    run_plan('kvm_automation_tooling::subplans::setup_cluster_ssh',
      'controllers'  => $controllers,
      'destinations' => $all_targets,
      'user'         => $user,
      'root_access'  => $setup_cluster_root_ssh,
    )
  }

  if $host_root_access {
    out::message("Authorizing host ssh public key on all vms as root: ${stdlib::to_json_pretty($all_targets)}")

    $host_public_key = file::read($ssh_public_key_path)
    run_task('kvm_automation_tooling::add_ssh_authorized_key',
      $all_targets,
      'user' => 'root',
      'ssh_public_key' => $host_public_key,
    )
  }

  if $install_openvox {
    $primary_target = $target_map.dig('primary', 0)
    run_plan('kvm_automation_tooling::install_openvox',
      $install_openvox_params + {
        'targets' => $all_targets,
        'puppetserver_target' => $primary_target,
        'puppetdb_target' => $primary_target,
        'postgresql_target' => $primary_target,
      }
    )
  }

  return($target_map)
}
