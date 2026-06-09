require 'spec_helper'

describe 'kvm_automation_tooling::calculate_wait_for_ip_timeout' do
  let(:matching_vms) do
    [
      {
        'role' => 'agent',
        'os'   => {
          'name'    => 'ubuntu',
          'version' => '2204',
          'arch'    => 'amd64'
        },
        'domain_type' => 'kvm'
      },
      {
        'role' => 'agent',
        'os'   => {
          'name'    => 'rocky',
          'version' => '10',
          'arch'    => 'x86_64'
        },
      },
    ]
  end
  let(:non_matching_vms) do
    [
      {
        'role' => 'agent',
        'os'   => {
          'name'    => 'ubuntu',
          'version' => '2204',
          'arch'    => 'arm64'
        },
        'domain_type' => 'kvm',
      },
      {
        'role' => 'agent',
        'os'   => {
          'name'    => 'debian',
          'version' => '13',
          'arch'    => 'amd64'
        },
      },
    ]
  end
  let(:qemu_domain) do
    [
      {
        'role' => 'agent',
        'os'   => {
          'name'    => 'ubuntu',
          'version' => '2204',
          'arch'    => 'amd64',
        },
        'domain_type' => 'qemu',
      },
    ]
  end

  context 'matching arch' do
    it 'returns the default timeout' do
      is_expected.to(
        run.with_params('amd64', matching_vms)
          .and_return(300)
      )
    end

    it 'returns the given default_timeout' do
      is_expected.to(
        run.with_params('amd64', matching_vms, 600)
          .and_return(600)
      )
    end
  end

  context 'non-matching arch' do
    it 'returns the qemu timeout' do
      is_expected.to(
        run.with_params('amd64', non_matching_vms)
          .and_return(900)
      )
      is_expected.to(
        run.with_params('arm64', matching_vms)
          .and_return(900)
      )
    end

    it 'returns the given qemu_timeout' do
      is_expected.to(
        run.with_params('amd64', non_matching_vms, 300, 1200)
          .and_return(1200)
      )
    end

    it 'returns the qemu timeout if host_arch is undef' do
      is_expected.to(
        run.with_params(nil, matching_vms)
          .and_return(900)
      )
    end

    it 'returns the qemu timeout if vm spec does not have os' do
      matching_vms[0].delete('os')
      is_expected.to(
        run.with_params('amd64', matching_vms)
          .and_return(900)
      )
    end

  end

  context 'qemu domain' do
    it 'returns the qemu timeout' do
      is_expected.to(
        run.with_params('amd64', qemu_domain)
          .and_return(900)
      )
    end
  end
end
