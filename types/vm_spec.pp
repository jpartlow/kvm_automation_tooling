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
# - os: Details of the operating system image to download and use
#   use for the vms. (see [Os_spec](./types/os_spec.pp))
# - cpus: The number of CPUs to allocate to each vm.
# - mem_mb: The amount of memory in MB to allocate to each vm.
# - disk_gb: The amount of disk space in GB to allocate to each vm.
# - cpu_mode: The CPU mode to use for the libvirt vm domains. Set this
#   to 'host-passthrough' to enable nested virtualization.
type Kvm_automation_tooling::Vm_spec = Struct[{
  role => String[1],
  Optional[count]      => Integer[1],
  Optional[os]         => Kvm_automation_tooling::Os_spec,
  Optional[cpus]       => Integer[1],
  Optional[mem_mb]     => Integer[1],
  Optional[disk_gb]    => Integer[1],
  Optional[cpu_mode]   => String[1],
}]
