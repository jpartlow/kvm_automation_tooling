# Translates a Debian or Ubuntu version number to codename, or
# codename to version number, depending on what it is given.
#
# Raises an error if unable to translate the given
# version_or_codename.
#
# If given something for an *os* other than debian or ubuntu, it
# returns what it was given.
#
# @param $os The operating system name (debian or ubuntu).
# @param $version_or_codename The version number (e.g., 10, 11, 12,
#   18.04, 20.04), or codename string (trixie, noble, etc.) to
#   translate.
function kvm_automation_tooling::translate_os_version_codename(
  Kvm_automation_tooling::Operating_system $os,
  Variant[Kvm_automation_tooling::Version,Pattern[/[a-z]+/]]
    $version_or_codename,
) {
  # Assuming that debian/ubuntu versions and codenames will never
  # overlap.
  $codenames = {
    # Debian
    '10' => 'buster',
    '11' => 'bullseye',
    '12' => 'bookworm',
    '13' => 'trixie',
    '14' => 'forky',
    # Ubuntu
    '1804' => 'bionic',
    '2004' => 'focal',
    '2204' => 'jammy',
    '2404' => 'noble',
  }
  $version_numbers = $codenames.reduce({}) |$hash, $v| {
    $hash + {
      $v[1] => $v[0]
    }
  }

  case $os {
    'debian','ubuntu': {
      if $version_or_codename =~ Kvm_automation_tooling::Version {
        $_version = ($os == 'debian') ? {
          true    => $version_or_codename.split('\.')[0],
          default => kvm_automation_tooling::get_normalized_ubuntu_version($version_or_codename),
        }
        $translation = $codenames[$_version]
      } else {
        $translation = $version_numbers[$version_or_codename]
      }
    }

    'ubuntu': {
      if $version_or_codename =~ Kvm_automation_tooling::Version {
        $translation = $ubuntu_codenames[$_version]
      } else {
        $translation = $ubuntu_version_numbers[$version_or_codename]
      }
    }

    default: {
      $translation = $version_or_codename
    }
  }

  if $translation =~ Undef {
    fail(@("EOS"/L))
      The kvm_automation_tooling::translate_os_version_codename() \
      function does not know the ${os} translation for \
      ${version_or_codename}. Does it need to be updated?
      | - EOS
  }

  return $translation
}
