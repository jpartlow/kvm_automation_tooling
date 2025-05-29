# Returns the Ubuntu version number without delimiters.
#
# @param version The Ubuntu version number, which may contain
#   delimiters like '.' or '_'.
# @return the Ubuntu version number without delimeters.
function kvm_automation_tooling::get_normalized_ubuntu_version(
  Pattern[/\d{2}[._]?\d{2}/] $version,
) {
  return regsubst($version, '[._]', '', 'G')
}
