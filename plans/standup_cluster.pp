# Standup one cluster of KVM virtual machines for a particular OS Puppet
# architecture.
#
# Makes use of terraform under the hood for vm initialization.
#
# @param $cluster_name This is combined with *architecture*, *os*,
# *os_version*, *os_arch* to obtain a reasonably unique id for the cluster.
# The *cluster_name* allows you to stand up more than one cluster of the
# same architecture and platform, for example.
# @param $architecture The Puppet services architecture of the cluster (see
# docs/ARCHITECTURE.md).
# @param $os The base operating system of the cluster.
# @param $os_version The version of the base operating system of the
# cluster.
# @param $os_arch The chip architecture of the base operating system of the
# cluster.
# @param $agents The number of Puppet agent vms to stand up in the cluster.
# @param $primary_cpus The number of CPUs to allocate to the primary vm.
# @param $primary_mem_mb The amount of memory in MB to allocate to the primary
# vm.
# @param $primary_disk_gb The amount of disk space in GB to allocate to the
# primary vm.
# @param $agent_cpus The number of CPUs to allocate to each agent vm.
# @param $agent_mem_mb The amount of memory in MB to allocate to each agent vm.
# @param $agent_disk_gb The amount of disk space in GB to allocate to each
# agent vm.
# @param $libvirt_images_dir The base directory where libvirt images are
# stored.
# @param $libvirt_group The group that owns the libvirt images directory.
plan kvm_automation_tooling::standup_cluster(
  String $cluster_name,
  String $user = system::env('USER'),
  Kvm_automation_tooling::Architectures $architecture = 'singular',
  Kvm_automation_tooling::Operating_systems $os,
  String $os_version,
  Kvm_automation_tooling::Os_arch $os_arch,
  Integer $agents = 1,
  Integer $primary_cpus = 4,
  Integer $primary_mem_mb = 8192,
  Integer $primary_disk_gb = 20,
  Integer $agent_cpus = 1,
  Integer $agent_mem_mb = 512,
  Integer $agent_disk_gb = 10,
  String $libvirt_images_dir = '/var/lib/libvirt/images',
  String $libvirt_group = 'libvirt',
) {
  $platform = "${os}-${os_version}-${os_arch}"
  $cluster_id = "${cluster_name}-${architecture}-${platform}"
  $primary_hostname = "${cluster_id}-primary"
  $agent_hostnames = $agents.map |$i| { "${cluster_id}-agent-${i}" }

  # Create libvirt images subdirectory.
  $images_dir = "${libvirt_images_dir}/${cluster_id}"
  run_command(@("EOS"), 'localhost', "Create libvirt images subdirectory ${images_dir}.")
    mkdir -p ${images_dir} && \
    chmod 755 ${images_dir} && \
    chown root:${libvirt_group} ${images_dir}
    |-EOS

  # Create terraform instance subdirectory for tfvars and tfstate.
  $terraform_instances_dir = "./terraform/instances/${cluster_id}"
  run_command(@("EOS"), 'localhost', "Creating terraform instances subdirectory ${terraform_instances_dir}.")
    mkdir -p ${terraform_instances_dir} && \
    chown ${user}:${user} ${terraform_instances_dir}
    |-EOS

  # Create cloud-init subdirectory.
  $cloud_init_dir = "./cloud-init/${cluster_id}"
  run_command(@("EOS"), 'localhost', "Creating cloud-init subdirectory ${cloud_init_dir}.")
    mkdir -p ${cloud_init_dir} && \
    chown ${user}:${user} ${cloud_init_dir}
    |-EOS

  # Generate cloud-init files.
#  probably from erb templates
  # Terraform apply.
}
