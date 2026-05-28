# Gathers and outputs libvirt state from localhost pertaining to
# vms identified by the given cluster_id.
#
# @param cluster_id The unique identifier for the cluster to gather
#   state for.
# @param vm_specs The array of vm specifications received by the plan.
plan kvm_automation_tooling::subplans::debug_libvirt_state(
  Kvm_automation_tooling::Cluster_id $cluster_id,
  Array[Kvm_automation_tooling::Vm_spec,1] $vm_specs,
) {
  $check_root = run_command('whoami', 'localhost', '_run_as' => 'root', '_catch_errors' => true)[0]
  $run_as_root = $check_root.ok()
  $cmd_args = {'_catch_errors' => true } + ($run_as_root ? {
    true    => {'_run_as' => 'root'},
    default => {},
  })

  $general_virsh_commands = [
    'virsh version',
    'virsh hostname',
    'virsh sysinfo',
    'virsh list --all',
    'virsh net-list --all',
    "virsh net-dhcp-leases ${cluster_id}",
    "virsh net-dumpxml ${cluster_id}",
    "brctl show",
    "nft list ruleset",
    "cat /var/lib/libvirt/dnsmasq/${cluster_id}.conf",
    "cat /var/lib/libvirt/dnsmasq/${cluster_id}.hostsfile",
    "cat /var/lib/libvirt/dnsmasq/${cluster_id}.addnhosts",
    "journalctl -u libvirtd --since '1 hour ago'",
  ] 
  $domain_virsh_commands = $vm_specs.map |$spec| {
    $role = $spec['role']
    $count = $spec['count'] =~ Undef ? {
      true    => 1,
      default => $spec['count'],
    }
    Integer[1, $count].map |$i| {
      $hostname = "${cluster_id}-${role}-${i}"
      [
        "virsh dominfo ${hostname}",
        "virsh domstate ${hostname} --reason",
        "virsh domblklist ${hostname} --details",
        "virsh domiflist ${hostname}",
        "virsh dumpxml ${hostname}",
        "virsh domifaddr ${hostname} --source lease",
        "virsh domifaddr ${hostname} --source arp",
        "cat /var/log/libvirt/qemu/${hostname}.log",
        "cat /var/log/libvirt/qemu/${hostname}-console.log",
      ]
    }
  }.flatten()
  ($general_virsh_commands + $domain_virsh_commands).each |$cmd| {
    $result = run_command($cmd, 'localhost', $cmd_args)[0]
    if $result.ok() {
      log::warn("${cmd} output:\n${result['merged_output']}")
    } else {
      log::error("${cmd} failed:\n${result['merged_output']}")
    }
  }
}
