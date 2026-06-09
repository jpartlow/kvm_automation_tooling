# Calculates the timeout for waiting for an IP address to be assigned
# to a VM.
#
# If any of the VMs are using the qemu domain type or if any
# of the VMs have an architecture that does not match the host
# architecture, then the $qemu_timeout value is returned.
#
# Otherwise, the $default_timeout value is returned.
#
# @param host_arch The architecture of the host machine.
# @param vm_specs An array of Vm_spec structs representing the VMs
#   being created.
# @param default_timeout The default timeout in seconds to use.
# @param qemu_timeout The timeout in seconds to use if any VMs are
#   using the qemu domain type or have an architecture that does not
#   match the host architecture.
# @return The timeout in seconds for waiting for an IP address to be
#   assigned to a VM.
function kvm_automation_tooling::calculate_wait_for_ip_timeout(
  Optional[Kvm_automation_tooling::Os_arch] $host_arch,
  Array[Kvm_automation_tooling::Vm_spec] $vm_specs,
  Integer $default_timeout = 300,
  Integer $qemu_timeout = 900,
) >> Integer {
  $domain_types = $vm_specs.map |$vm_spec| {
    $vm_spec['domain_type']
  }.unique()
  $architectures = $vm_specs.map |$vm_spec| {
    dig($vm_spec, 'os', 'arch')
  }.unique()
  $normalized_host_arch = kvm_automation_tooling::get_normalized_libvirt_arch($host_arch)

  $any_qemu_domains = $domain_types.any |$domain_type| {
    $domain_type == 'qemu'
  }

  $any_arch_mismatch = $architectures.any |$arch| {
    $normalized_arch = kvm_automation_tooling::get_normalized_libvirt_arch($arch)
    ($normalized_arch =~ Undef) or
      ($normalized_arch != $normalized_host_arch)
  }

  if ($any_qemu_domains or $any_arch_mismatch) {
    $wait_for_ip_timeout = $qemu_timeout
  } else {
    $wait_for_ip_timeout = $default_timeout
  }

  $wait_for_ip_timeout
}
