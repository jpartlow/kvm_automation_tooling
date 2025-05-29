# Expand a VM specification hash by filling in defaults from a given
# Hash.
#
# @param vm_spec The VM specification to fill in.
# @param defaults The defaults to override.
# @return A new VM specification hash with defaults filled in.
function kvm_automation_tooling::fill_vm_spec(
  Kvm_automation_tooling::Vm_spec $vm_spec,
  Kvm_automation_tooling::Vm_spec $defaults,
) >> Kvm_automation_tooling::Vm_spec {
  $defaults + $vm_spec
}
