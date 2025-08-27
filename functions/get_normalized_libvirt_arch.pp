# Return the expected architecture strings for libvirt. (x86_64,
# aarch64)
#
# @param arch The architecture to normalize.
# @return The normalized architecture string.
function kvm_automation_tooling::get_normalized_libvirt_arch(
  Optional[Kvm_automation_tooling::Os_arch] $arch,
) {
  $arch ? {
    'amd64'  => 'x86_64',
    'arm64'  => 'aarch64',
    default  => $arch,
  }
}
