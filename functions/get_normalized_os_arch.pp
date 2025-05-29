# Return the expected architecture strings for the given os. (amd64,
# arm64 for debian/ubuntu, and x86_64, aarch64 for others)
#
# @param os The operating system name (debian, ubuntu, or others).
# @param arch The architecture to normalize.
# @return The normalized architecture string.
function kvm_automation_tooling::get_normalized_os_arch(
  Kvm_automation_tooling::Operating_system $os,
  Kvm_automation_tooling::Os_arch $arch,
) {
  case $os {
    'debian','ubuntu': {
      $arch ? {
        'x86_64'  => 'amd64',
        'aarch64' => 'arm64',
        default   => $arch,
      }
    }
    default: {
      $arch ? {
        'amd64' => 'x86_64',
        'arm64' => 'aarch64',
        default => $arch,
      }
    }
  }
}
