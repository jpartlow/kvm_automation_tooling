# Specification for a set of vms of some count.
#
# Only the base role key is required. The rest of the keys are optional
# so that a set of common parameters can be used with the fill_vm_spec()
# function to supply any missing defaults.
#
# Keys:
# - role: The role of the vms in set. Will be used as part of the
#   hostname along with the cluster-id and the vm count. (Required)
# - count: The number of vms in the set.
# - os: The operating system of the vms.
# - os_version: The version of the operating system of the vms.
# - os_arch: The chip architecture of the operating system of the vms.
# - cpus: The number of CPUs to allocate to each vm.
# - mem_mb: The amount of memory in MB to allocate to each vm.
# - disk_gb: The amount of disk space in GB to allocate to each vm.
# - cpu_mode: The CPU mode to use for the libvirt vm domains. Set this
#   to 'host-passthrough' to enable nested virtualization.
type Kvm_automation_tooling::Vm_spec = Struct[{
  role => String[1],
  Optional[count]      => Integer[1],
  Optional[os]         => Kvm_automation_tooling::Operating_system,
  Optional[os_version] => Kvm_automation_tooling::Version,
  Optional[os_arch]    => Kvm_automation_tooling::Os_arch,
  Optional[cpus]       => Integer[1],
  Optional[mem_mb]     => Integer[1],
  Optional[disk_gb]    => Integer[1],
  Optional[cpu_mode]   => String[1],
}]
