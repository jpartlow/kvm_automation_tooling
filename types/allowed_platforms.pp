# Enumeration of platforms that the module can pull images for.
type Kvm_automation_tooling::Allowed_platforms = Enum[
  'almalinux-8-x86_64',
  'almalinux-9-x86_64',
  'debian-10-amd64',
  'debian-11-amd64',
  'debian-12-amd64',
  'debian-13-amd64',
  'rocky-8-x86_64',
  'rocky-9-x86_64',
  'ubuntu-1804-amd64',
  'ubuntu-2004-amd64',
  'ubuntu-2204-amd64',
  'ubuntu-2404-amd64',
]
