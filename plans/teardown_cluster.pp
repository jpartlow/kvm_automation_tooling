# This plan is just a wrapper around the terraform::destroy plan
# that automatically sets the dir, state and vars_file parameters based
# on the given cluster_id:
#
#   "$cluster_name-$architecture-$os-$os_version-$os_rarch"
#
# It also cleans up state in the terraform/instances directory and removes
# the local cluster specific inventory file.
#
# @param cluster_id The unique identifier for the cluster to destroy.
# @param terraform_state_dir The directory where terraform state files
#   are stored. This should be an absolute or Puppet module relative
#   path that the find_files function can locate.
plan kvm_automation_tooling::teardown_cluster(
  String $cluster_id,
  String $terraform_state_dir = 'kvm_automation_tooling/../terraform/instances',
) {
  $terraform_dir = './terraform'
  $_terraform_state_dir = find_file($terraform_state_dir)
  $tfvars_file = "${_terraform_state_dir}/${cluster_id}.tfvars.json"
  $tfstate_file = "${_terraform_state_dir}/${cluster_id}.tfstate"
  $inventory_file = "${_terraform_state_dir}/inventory.${cluster_id}.yaml"

  run_plan('terraform::destroy',
    'dir'      => $terraform_dir,
    'state'    => $tfstate_file,
    'var_file' => $tfvars_file,
  )

  if file::exists($tfstate_file) {
    file::delete($tfstate_file)
  }
  if file::exists($tfvars_file) {
    file::delete($tfvars_file)
  }
  if file::exists($inventory_file) {
    file::delete($inventory_file)
  }
}
