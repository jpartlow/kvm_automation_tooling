# Manually resolve target references from the given *inventory_file* and
# return those from the given *group*.
#
# @param inventory_file Absolute path to a Bolt inventory file
#   configured with the tfstate files for the cluster we are resolving
#   targets for.
# @param group_name The name of the inventory group to pass to the
#   resolve_references function.
# @return [Array<Hash>] An array of target hashes.
function kvm_automation_tooling::resolve_terraform_targets(
  Stdlib::AbsolutePath $inventory_file,
  String $group_name,
) {
  log::debug("Inventory file: ${inventory_file}")

  $inventory = loadyaml($inventory_file, {})
  log::debug("Loaded inventory: ${inventory}")

  $config = $inventory.get('config', {})
  log::debug("Config: ${config}")

  $group = $inventory.dig('groups').then |$groups| {
    $groups.filter |$group| {
      $group['name'] == $group_name
    }[0]
  }
  if $group =~ Undef {
    fail("Did not find group '${group_name}' in inventory:\n${inventory}")
  }
  log::debug("The ${group_name} group: ${group}")

  $group_vars = $group.get('vars', {})
  log::debug("Group vars: ${group_vars}")

  $refs = resolve_references($group)
  log::debug("Resolved references for '${group_name}': ${refs}")

  $updated_refs = $refs['targets'].map |$r| {
    $r + {
      'vars'   => $group_vars + $r.get('vars', {}),
      'config' => $config + $r.get('config', {}),
    }
  }
  log::debug("Updated references: ${updated_refs}")

  $targets = $updated_refs.map |$r| {
    Target.new($r)
  }
  log::debug($targets.map |$t| {
    {
      name   => $t.name,
      host   => $t.host,
      uri    => $t.uri,
      user   => $t.user,
      config => $t.config,
      vars   => $t.vars,
    }
  })

  return $targets
}
