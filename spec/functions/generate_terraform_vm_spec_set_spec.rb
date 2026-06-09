require 'spec_helper'

describe 'kvm_automation_tooling::generate_terraform_vm_spec_set' do
  let(:cluster_id) { 'spec' }
  let(:vm_specs) do
    [
      {
        'role' => 'primary',
        'os' => {
          'name' => 'ubuntu',
          'version' => '24.04',
          'arch' => 'x86_64',
        },
        'cpus' => 4,
        'mem_mb' => 4096,
        'disk_gb' => 20,
      },
      {
        'role' => 'agent',
        'count' => 2,
        'os' => {
          'name' => 'rocky',
          'version' => '9',
          'arch' => 'x86_64',
        },
      },
      {
        'role' => 'agent',
        'os' => {
          'name' => 'rocky',
          'version' => '9',
          'arch' => 'aarch64',
        },
        'cpus' => 2,
      },
      {
        'role' => 'agent',
        'os' => {
          'name' => 'ubuntu',
          'version' => '24.04',
          'arch' => 'arm64',
        },
      },
    ]
  end
  let(:image_results) do
    [
      {
        'platform' => 'ubuntu-2404-amd64',
        'base_image_url' => 'http://example-rspec/noble-server.img',
        'base_volume_name' => 'noble-server.img',
        'pool_name' => 'ubuntu-2404-amd64.pool',
        'pool_path' => 'ubuntu-2404-amd64',
      },
      {
        'platform' => 'ubuntu-2404-arm64',
        'base_image_url' => 'http://example-rspec/noble-server-arm64.img',
        'base_volume_name' => 'noble-server-arm64.img',
        'pool_name' => 'ubuntu-2404-arm64.pool',
        'pool_path' => 'ubuntu-2404-arm64',
      },
      {
        'platform' => 'rocky-9-x86_64',
        'base_image_url' => 'http://example-rspec/rocky-9.qcow2',
        'base_volume_name' => 'rocky-9.qcow2',
        'pool_name' => 'rocky-9-x86_64.pool',
        'pool_path' => 'rocky-9-x86_64',
      },
      {
        'platform' => 'rocky-9-aarch64',
        'base_image_url' => 'http://example-rspec/rocky-9-aarch64.qcow2',
        'base_volume_name' => 'rocky-9-aarch64.qcow2',
        'pool_name' => 'rocky-9-aarch64.pool',
        'pool_path' => 'rocky-9-aarch64',
      },
    ]
  end

  it 'returns an empty hash for an empty specs array' do
    is_expected.to run.with_params('spec', [], [])
      .and_return({})
    is_expected.to run.with_params('spec', [], image_results)
      .and_return({})
  end

  it 'returns a hash of per vm terraform objects keyed by hostname' do
    is_expected.to(
      run.with_params(cluster_id, vm_specs, image_results)
        .and_return(
          {
            'primary.spec-primary-1.ubuntu-2404-amd64' => {
              'cpus' => 4,
              'mem_mb' => 4096,
              'disk_gb' => 20,
              'base_volume_name' => 'noble-server.img',
              'pool_name' => 'ubuntu-2404-amd64.pool',
              'os' => 'ubuntu',
              'arch' => 'x86_64',
            },
            'agent.spec-agent-1.rocky-9-x86_64' => {
              'base_volume_name' => 'rocky-9.qcow2',
              'pool_name' => 'rocky-9-x86_64.pool',
              'os' => 'rocky',
              'arch' => 'x86_64',
            },
            'agent.spec-agent-2.rocky-9-x86_64' => {
              'base_volume_name' => 'rocky-9.qcow2',
              'pool_name' => 'rocky-9-x86_64.pool',
              'os' => 'rocky',
              'arch' => 'x86_64',
            },
            'agent.spec-agent-3.rocky-9-aarch64' => {
              'cpus' => 2,
              'base_volume_name' => 'rocky-9-aarch64.qcow2',
              'pool_name' => 'rocky-9-aarch64.pool',
              'os' => 'rocky',
              'arch' => 'aarch64',
            },
            'agent.spec-agent-4.ubuntu-2404-arm64' => {
              'base_volume_name' => 'noble-server-arm64.img',
              'pool_name' => 'ubuntu-2404-arm64.pool',
              'os' => 'ubuntu',
              'arch' => 'aarch64',
            },
          }
        )
    )
  end
end
