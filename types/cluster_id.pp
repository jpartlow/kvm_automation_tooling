# Constraint for the string identifier for a vm cluster.
type Kvm_automation_tooling::Cluster_id = Pattern[/\A[a-zA-Z0-9-]+\Z/]
