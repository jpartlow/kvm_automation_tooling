# Download cloud-init logs from a set of targets for local review.
#
# @param targets The targets to download cloud-init logs from.
# @param local_log_dir The local directory to store the logs in.
plan kvm_automation_tooling::dev::get_cloud_init_logs(
  TargetSpec $targets,
  String $local_log_dir = './tmp',
) {
  $local_user = system::env('USER')
  $local_cloud_init = "${local_log_dir}/cloud-init"
  $local_cloud_init_output = "${local_log_dir}/cloud-init-output"
  run_command("mkdir -p ${local_cloud_init} ${local_cloud_init_output}", 'localhost', '_run_as' => $local_user)

  $hostname_results = run_command('hostname', $targets)
  $cloud_init_results = download_file('/var/log/cloud-init.log', 'cloud-init', $targets)
  $cloud_init_output_results = download_file('/var/log/cloud-init-output.log', 'cloud-init-output', $targets)
  $hostname_results.each |$result| {
    $target = $result.target()
    $hostname = $result['stdout'].strip()
    $cloud_init_path = $cloud_init_results.find($target.name()).value['path']
    $cloud_init_output_path = $cloud_init_output_results.find($target.name()).value['path']
    run_command(@("EOS"), 'localhost', '_run_as' => $local_user)
      mv ${cloud_init_path} ${local_cloud_init}/cloud-init.${hostname}.log
      |- EOS
    run_command(@("EOS"), 'localhost', '_run_as' => $local_user)
      mv ${cloud_init_output_path} ${local_cloud_init_output}/cloud-init-output.${hostname}.log
      |- EOS
  }
}
