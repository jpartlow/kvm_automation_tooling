# Returns the Ubuntu version name based on the version number.
function kvm_automation_tooling::get_ubuntu_version_name(
  Kvm_automation_tooling::Version $version,
) {
  $ubuntu_version_names = {
    '1804' => 'bionic',
    '2004' => 'focal',
    '2204' => 'jammy',
    '2404' => 'noble',
  }
  $_version = kvm_automation_tooling::get_normalized_ubuntu_version($version)
  return $ubuntu_version_names[$_version]
}
