# This plan generates a single passphraseless ssh keypair, distributes
# it as the default keypair for the given user on all controller VMs,
# and adds the public key to the authorized_keys file of the user on
# each destination VM.
#
# This is intended for use on development clusters where the vms
# need a simple way to interact with each other via ssh. (Typically
# a particular runner node will execute acceptance tests across the
# cluster via ssh.)
#
# There is nothing secure about this plan :) It is purely a testing
# convenience.
#
# @param $controllers The target spec for the controller VMs that will
#   receive the generated ssh keypair.
# @param $destinations The target spec for the VMs that controllers
#   are authorized to log into.
# @param $user The user ssh account on the vms.
# @param $key_type The type of ssh key to generate. (ed25519 or rsa)
plan kvm_automation_tooling::subplans::setup_inter_cluster_ssh(
  TargetSpec $controllers,
  TargetSpec $destinations,
  String $user,
  String $key_type = 'ed25519',
) {
  if $controllers.empty() {
    out::message('No controller VMs found. Skipping inter-cluster ssh setup.')
    return
  }

  $ssh_results = run_task('kvm_automation_tooling::generate_keypair',
    'localhost',
    'type' => $key_type,
  )[0]

  $tmp_dir = $ssh_results['tmpdir']
  $ssh_key_file = $ssh_results['keyfile']
  $ssh_public_key_file = $ssh_results['pubkeyfile']
  $ssh_public_key = $ssh_results['pubkey']

  $remote_public_key_path = "/home/${user}/.ssh/${ssh_public_key_file}"
  $remote_authorized_keys_path = "/home/${user}/.ssh/authorized_keys"


  $upload_result = catch_errors() || {
    out::message("Uploading ssh keypair to controller VMs: ${stdlib::to_json_pretty($controllers)}")
    upload_file(
      "${tmp_dir}/${ssh_key_file}",
      "/home/${user}/.ssh/${ssh_key_file}",
      $controllers,
    )
    upload_file(
      "${tmp_dir}/${ssh_public_key_file}",
      "/home/${user}/.ssh/${ssh_public_key_file}",
      $controllers,
    )
    run_command("chown -R ${user}:${user} /home/${user}/.ssh/${ssh_key_file}*", $controllers)

    out::message("Authorizing ssh public key on destination vms: ${stdlib::to_json_pretty($destinations)}")
    run_command(@("EOS"), $destinations)
      echo "${ssh_public_key}" >> "${remote_authorized_keys_path}"
      chmod 600 "${remote_authorized_keys_path}"
      chown ${user}:${user} "${remote_authorized_keys_path}"
      | EOS
  }
  if file::exists($tmp_dir) {
    run_command("rm -rf ${tmp_dir}", 'localhost')
  }

  if $upload_result =~ Error {
    fail_plan($upload_result)
  }
}
