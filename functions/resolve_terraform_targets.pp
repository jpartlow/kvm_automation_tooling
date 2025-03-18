# Manually resolve target references from the given *inventory_file* and
# return those with the given *role*.
#
# @param inventory_file Absolute path to a Bolt inventory file
#   configured with the tfstate files for the cluster we are resolving
#   targets for.
# @param role The role to filter targets by (filters against the name,
#   which is set by hostname).
# @param group The name of the inventory group to pass to the
#   resolve_references function.
# @return [Array<Hash>] An array of target hashes.
function kvm_automation_tooling::resolve_terraform_targets(
  Stdlib::AbsolutePath $inventory_file,
  String $role,
  String $group_name = 'puppet',
) {
  log::debug("Inventory file: ${inventory_file}")

  $inventory = loadyaml($inventory_file)
  log::debug("Loaded inventory: ${inventory}")

  $config = $inventory['config']
  log::debug("Config: ${config}")

  $puppet_group = $inventory['groups'].filter |$group| {
    $group['name'] == $group_name
  }[0]
  if $puppet_group =~ Undef {
    fail("Did not find group '${group}' in inventory:\n${inventory}")
  }
  log::debug("Puppet group: ${puppet_group}")

  $domain = $puppet_group['vars']['domain_name']
  log::debug("Domain: ${domain}")

  $refs = resolve_references($puppet_group)
  log::debug("Resolved references for 'puppet': ${refs}")

  $refs_in_role = $refs['targets'].filter |$r| {
    $r['name'] =~ "^${role}"
  }
  log::debug("Resolved references in role ${role}: ${refs_in_role}")

  $refs_in_role_with_fqdn = $refs_in_role.map |$r| {
    $_r = $r + {
      'name' => "${r['name']}.${domain}",
    }
    $config =~ NotUndef ? {
      true    => $_r + { 'config' => $config },
      default => $_r,
    }
  }
  log::debug("Updated references: ${refs_in_role_with_fqdn}")

  $targets = $refs_in_role_with_fqdn.map |$r| {
    Target.new($r)
  }
  log::debug($targets.map |$t| {
    {
      name => $t.name,
      host => $t.host,
      uri  => $t.uri,
      user => $t.user,
      config => $t.config,
      vars => $t.vars,
    }
  })

  return $targets
}
