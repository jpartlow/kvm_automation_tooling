# Matches an OpenVox x.y.z version, a version based off that with some
# trailing text (such as x.y.z-rc1 or a git describe like
# x.y.z-123-gabcdef), or the string 'latest'.
type Kvm_automation_tooling::Openvox_version = Variant[
  Pattern[/^\d+(\.\d+){2}(-.+)?/],
  Enum['latest'],
]
