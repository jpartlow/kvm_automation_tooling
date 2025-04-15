# This plan manages two aspects of ssh access within the cluster.
#
# 1. SSH between *controller* and *destination* vms as *user*.
# 2. SSH between *controller* and *destination* vms as *root*.
#
# The plan generates a single passphraseless ssh keypair, distributes
# it as the default keypair for the given user on all controller VMs,
# and adds the public key to the authorized_keys file of the user on
# each destination VM. If root_access is true, the public key is also
# added to the authorized_keys file of the root user on each
# destination VM.
#
# This is intended for use on development clusters where the vms
# need a simple way to interact with each other via ssh. (Typically
# a particular runner node will execute acceptance tests across the
# cluster via ssh, either as the *user* or as root.)
#
# There is nothing secure about this plan :) It is purely a testing
# convenience.
#
# If controllers is an empty set, nothing is done.
#
# @param $controllers The target spec for the controller VMs that will
#   receive the generated ssh keypair.
# @param $destinations The target spec for the VMs that controllers
#   are authorized to log into.
# @param $user The user ssh account on the vms.
# @param $key_type The type of ssh key to generate. (ed25519 or rsa)
# @param $root_access Whether to allow root access to the destination
#   VMs. (Required for Beaker, for example.)
plan kvm_automation_tooling::subplans::setup_cluster_ssh(
  TargetSpec $controllers,
  TargetSpec $destinations,
  String[1] $user,
  String[1] $key_type = 'ed25519',
  Boolean $root_access = true,
) {
  if $controllers.empty() {
    out::message('No controller VMs found. Skipping internal cluster ssh setup.')
  } else {

    $ssh_results = run_task('kvm_automation_tooling::generate_keypair',
      'localhost',
      'type' => $key_type,
    )[0]

    $tmp_dir = $ssh_results['tmpdir']
    $ssh_key_file = $ssh_results['keyfile']
    $ssh_public_key_file = $ssh_results['pubkeyfile']
    $ssh_public_key = $ssh_results['pubkey']

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

      out::message("Authorizing ssh public key on destination vms as ${user}: ${stdlib::to_json_pretty($destinations)}")
      run_task('kvm_automation_tooling::add_ssh_authorized_key',
        $destinations,
        'user' => $user,
        'ssh_public_key' => $ssh_public_key,
      )

      if $root_access {
        out::message("Authorizing ssh public key on destination vms as root: ${stdlib::to_json_pretty($destinations)}")
        run_task('kvm_automation_tooling::add_ssh_authorized_key',
          $destinations,
          'user' => 'root',
          'ssh_public_key' => $ssh_public_key,
        )
      }
    }
    if file::exists($tmp_dir) {
      run_command("rm -rf ${tmp_dir}", 'localhost')
    }

    if $upload_result =~ Error {
      fail_plan($upload_result)
    }
  }
}
