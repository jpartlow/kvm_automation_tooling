# Given a TargetSpec, obtain platform details from each and set a
# *platform* variable on each Target.
#
# This plan takes advantage of the fact that Target state is
# preserved in the inventory in memory, so a calling plan will see the
# *platform* variables so long as it is working with actual Target
# objects.
plan kvm_automation_tooling::subplans::lookup_platform(
  TargetSpec $targets,
) {
  $_targets = get_targets($targets)
  run_plan('facts', 'targets' => $_targets)

  $targets_with_platforms = $_targets.map |$target| {
    # The facts plan will always provide these values, regardless
    # of whether puppet/facter are present on the target:
    $os = downcase(dig($target.facts, 'os', 'name'))
    $os_full_version = dig($target.facts, 'os', 'release', 'full')
    # However, there is a case where version may be 'n/a' or
    # something like 'trixie/sid'.
    # This is the case for Debian pre-release images.
    # For this case we need to fallback to translating the codename.
    if $os_full_version !~ Kvm_automation_tooling::Version {
      $codename = dig($target.facts, 'os', 'distro', 'codename')
      $os_version = kvm_automation_tooling::translate_os_version_codename($os, $codename)
    } else {
      $os_version = $os_full_version
    }

    # But architecture will only be in the facts if facter was present.
    if dig($target.facts, 'os', 'architecture') =~ Undef {
      $os_arch = run_command('uname -m', $target)[0]['stdout'].strip
    } else {
      $os_arch = dig($target.facts, 'os', 'architecture')
    }

    $platform = kvm_automation_tooling::platform(
      'name'    => $os,
      'version' => $os_version,
      'arch'    => $os_arch,
    )
    $target.set_var('platform', $platform)
  }

  return $targets_with_platforms
}
