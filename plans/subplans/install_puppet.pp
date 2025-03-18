# Install Puppet agents and primary services on the cluster.
#
# This plan takes Bolt Target objects for parameters and is not intended
# to be called manually
#
# @param targets The targets to install the Puppet agent on.
# @param puppetserver_target The target to install the Puppet server on.# @param puppetdb_target The target to install the PuppetDB on.
# @param postgresql_target The target to install PostgreSQL on.
plan kvm_automation_tooling::subplans::install_puppet(
  Array[Target] $targets,
  Target $puppetserver_target,
  Target $puppetdb_target,
  Target $postgresql_target,
) {
  apply_prep($targets)

}
