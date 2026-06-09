require 'spec_helper'

describe 'plan: debug_libvirt_state' do
  include_context 'plan_init'

  let(:hostnames) { ['spec-vm-1', 'spec-vm-2'] }
  let(:params) do
    {
      'cluster_id'   => 'spec',
      'vm_hostnames' => hostnames,
    }
  end
  let(:general_commands) do
    [
      'virsh version',
      'virsh hostname',
      'virsh sysinfo',
      'virsh list --all',
      'virsh net-list --all',
      "virsh net-dhcp-leases spec",
      "virsh net-dumpxml spec",
      "brctl show",
      "nft list ruleset",
      "cat /var/lib/libvirt/dnsmasq/spec.conf",
      "cat /var/lib/libvirt/dnsmasq/spec.hostsfile",
      "cat /var/lib/libvirt/dnsmasq/spec.addnhosts",
      "journalctl -u libvirtd --since '1 hour ago'",
    ]
  end
  let (:domain_commands) do
    hostnames.map do |hostname|
      [
        "virsh dominfo #{hostname}",
        "virsh domstate #{hostname} --reason",
        "virsh domblklist #{hostname} --details",
        "virsh domiflist #{hostname}",
        "virsh dumpxml #{hostname}",
        "virsh domifaddr #{hostname} --source lease",
        "virsh domifaddr #{hostname} --source arp",
        "cat /var/log/libvirt/qemu/#{hostname}.log",
        "cat /var/log/libvirt/qemu/#{hostname}-console.log",
      ]
    end.flatten
  end

  it 'runs' do
    expect_command('true')
      .with_targets(['localhost'])
      .error_with('msg' => 'cannot run as root', 'kind' => 'error')
    [general_commands, domain_commands].flatten.each do |cmd|
      expect_command(cmd)
        .with_params({'_catch_errors' => true})
        .with_targets(['localhost'])
    end

    result = run_plan('kvm_automation_tooling::subplans::debug_libvirt_state', params)
    expect(result.ok?).to(eq(true), result.value)
  end

  it 'runs as root' do
    expect_command('true')
      .with_targets(['localhost'])
    [general_commands, domain_commands].flatten.each do |cmd|
      expect_command(cmd)
        .with_params({'_catch_errors' => true, '_run_as' => 'root'})
        .with_targets(['localhost'])
    end
    result = run_plan('kvm_automation_tooling::subplans::debug_libvirt_state', params)
    expect(result.ok?).to(eq(true), result.value)
  end
end
