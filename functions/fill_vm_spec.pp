# Expand a VM specification hash by filling in defaults from a given
# Hash.
function kvm_automation_tooling::fill_vm_spec(
  Kvm_automation_tooling::Vm_spec $vm_spec,
  Kvm_automation_tooling::Vm_spec $defaults,
) >> Kvm_automation_tooling::Vm_spec {
  $defaults + $vm_spec
}
