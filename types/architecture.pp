# Enumeration of possible OS architectures. See docs/ARCHITECTURE.md for
# more information.
type Kvm_automation_tooling::Architecture = Enum[
  'singular',
  'separated',
  'dual',
]
