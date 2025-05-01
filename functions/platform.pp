# Generic function to produce a canonical descriptive platform string
# from a set of os, version and cpu arch values.
function kvm_automation_tooling::platform(
  Kvm_automation_tooling::Os_spec $os_spec,
) {
  $os = $os_spec['name']
  $version = $os_spec['version']
  $arch = $os_spec['arch']

  $_arch = kvm_automation_tooling::get_normalized_os_arch($os, $arch)

  case $os {
    'ubuntu': {
      $_version = kvm_automation_tooling::get_normalized_ubuntu_version($version)
      "${os}-${_version}-${_arch}"
    }
    default: {
      "${os}-${version}-${_arch}"
    }
  }
}
