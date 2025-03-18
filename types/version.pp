# General type constraint for version strings such as 2404, 24.04, 7, 7.2, 7_0, etc.
type Kvm_automation_tooling::Version = Pattern[/^\d+([._]\d+)*$/]
