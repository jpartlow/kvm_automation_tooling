# Returns the Debian or Ubuntu version codename based on the version
# number.
#
# @param $os The operating system name (debian or ubuntu).
# @param $version The version number (e.g., 10, 11, 12, 18.04, 20.04).
function kvm_automation_tooling::get_os_version_name(
  Enum['debian','ubuntu'] $os,
  Kvm_automation_tooling::Version $version,
) {
  case $os {

    'debian': {
      $debian_version_names = {
        '10' => 'buster',
        '11' => 'bullseye',
        '12' => 'bookworm',
        '13' => 'trixie',
      }
      $_major_version = $version.split('\.')[0]
      $codename = $debian_version_names[$_major_version]
    }

    'ubuntu': {
      $ubuntu_version_names = {
        '1804' => 'bionic',
        '2004' => 'focal',
        '2204' => 'jammy',
        '2404' => 'noble',
      }
      $_version = kvm_automation_tooling::get_normalized_ubuntu_version($version)
      $codename = $ubuntu_version_names[$_version]
    }

    default: {
      fail(@("EOS"/L))
        The kvm_automation_tooling::get_os_version_name() function \
        has no handling of ${os}. The function's os enum must have \
        been expanded without adding a case to support it...
        | - EOS
    }
  }

  if $codename =~ Undef {
    fail(@("EOS"/L))
      The kvm_automation_tooling::get_os_version_name() function \
      does not know the ${os} codename for ${version}. Does it need \
      to be updated?
      | - EOS
  }

  return $codename
}
