# Specification for a particular operating system.
#
# Used to determine canonical platform strings and image urls.
#
# Keys:
# - name: The name of the operating system (e.g. 'ubuntu', 'debian').
# - version: The version of the operating system (e.g. '22.04', '11').
# - arch: The architecture of the operating system (e.g. 'x86_64',
#   'aarch64').
# - image_version: A specific image version to download. (The latest
#   released version is downloaded if this is not set.)
#   Examples:
#     * Debian
#       - daily-latest (use this for the latest pre-release version)
#       - daily-YYYYMMDD-\d\d\d\d
#       - YYYYMMDD-\d\d\d\d
#     * Ubuntu
#       - YYYYMMDD
# - image_url_override: Complete URL pointing to the specific image to
#   download. Can be provided to bypass image url construction entirely.
type Kvm_automation_tooling::Os_spec = Struct[{
  name    => Kvm_automation_tooling::Operating_system,
  version => Kvm_automation_tooling::Version,
  arch    => Kvm_automation_tooling::Os_arch,
  Optional[image_version]      => Optional[String[1]],
  Optional[image_url_override] => Optional[Stdlib::HTTPUrl],
}]
