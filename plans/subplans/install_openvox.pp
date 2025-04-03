# Install OpenVox Puppet agents and primary services on the cluster.
#
# This plan takes Bolt Target objects for parameters and is not intended
# to be called manually
#
# @param targets The targets to install the Puppet agent on.
# @param puppetserver_target The target to install the Puppet server on.
# @param puppetdb_target The target to install the PuppetDB on.
# @param postgresql_target The target to install PostgreSQL on.
plan kvm_automation_tooling::subplans::install_openvox(
  Array[Target] $targets,
  Optional[Target] $puppetserver_target,
  Optional[Target] $puppetdb_target,
  Optional[Target] $postgresql_target,
) {
  apply_prep($targets)

  # TODO: Apply manifests to standup the server services.
}
