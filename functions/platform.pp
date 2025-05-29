# Generic function to produce a canonical descriptive platform string
# from a set of os, version and cpu arch values.
#
# Examples:
#   kvm_automation_tooling::platform({
#     'name'    => 'ubuntu',
#     'version' => '22.04',
#     'arch'    => 'x86_64',
#   })
#   # => "ubuntu-2204-amd64"
#
#   kvm_automation_tooling::platform({
#     'name'    => 'rocky',
#     'version' => '8',
#     'arch'    => 'x86_64',
#   })
#   # => "rocky-8-x86_64"
#
# @param os_spec A hash containing the operating system name, version,
#   and architecture.
# @return A string in the format "os-version-arch" after munging
#   version and arch for platform.
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
    }
    default: {
      $_version = $version.split('\.')[0]
    }
  }

  "${os}-${_version}-${_arch}"
}
