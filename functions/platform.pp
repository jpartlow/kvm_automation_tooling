# Generic function to produce a cononical descriptive platform string from
# a set of os, version and cpu arch values.
function kvm_automation_tooling::platform(
  Variant[
    Struct[{
      os         => Kvm_automation_tooling::Operating_system,
      os_version => Kvm_automation_tooling::Version,
      os_arch    => Kvm_automation_tooling::Os_arch,
    }],
    Kvm_automation_tooling::Vm_spec
  ] $vm_spec,
) {
  $os = $vm_spec['os']
  $version = $vm_spec['os_version']
  $arch = $vm_spec['os_arch']
  if [$os, $version, $arch].any |$v| {$v =~ Undef } {
    fail("An os, os_version, and os_arch must be set in the vm_spec. Received: ${vm_spec}")
  }

  case $os {
    'ubuntu': {
      $_version = kvm_automation_tooling::get_normalized_ubuntu_version($version)
      $_arch = $arch ? {
        'x86_64'  => 'amd64',
        'aarch64' => 'arm64',
        default   => $arch,
      }
      "${os}-${_version}-${_arch}"
    }
    default: {
      fail("TODO: Implement support for operating system: ${os}")
    }
  }
}
