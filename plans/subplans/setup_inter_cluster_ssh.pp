# This plan generates a single passphraseless ssh keypair, distributes
# it as the default keypair for the given user on all VMs in the
# cluster, and adds the public key to the authorized_keys file of
# the user on each VM.
#
# This is intended for use on development clusters where the vms
# need a simple way to interact with each other via ssh. (Typically
# a particular runner node will execute acceptance tests across the
# cluster via ssh.)
#
# There is nothing secure about this plan :) It is purely a testing
# convenience.
plan kvm_automation_tooling::subplans::setup_inter_cluster_ssh(
  TargetSpec $targets,
  String $user,
  String $key_type = 'ed25519',
) {
  $ssh_results = run_task('kvm_automation_tooling::generate_keypair', $targets, {
    'type' => $key_type,
  })

  catch_errors() {
    $tmp_dir = $ssh_results['tmpdir']
    $ssh_key_file = $ssh_results['keyfile']
    $ssh_public_key_file = $ssh_results['publickeyfile']

    $remote_public_key_path = "/home/${user}/.ssh/${ssh_public_key_file}"
    $remote_authorized_keys_path = "/home/${user}/.ssh/authorized_keys"

    upload_file($tmp_dir, "/home/${user}/.ssh", $targets, "Uploading ssh key files to /home/${user}/.ssh/")
    run_command(@("EOS"), $targets)
      chmod 600 "/home/${user}/.ssh/${ssh_key_file}*"
      chown -R ${user}:${user} "/home/${user}/.ssh/${ssh_key_file}*"
      | EOS
    run_command(@("EOS"), $targets)
      cat "${remote_public_key_path}" >> "${remote_authorized_keys_path}"
      chmod 600 "${remote_authorized_keys_path}"
      chown ${user}:${user} "${remote_authorized_keys_path}"
      | EOS
  }
  delete tmp_dir...
}
