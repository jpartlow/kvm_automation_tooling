require 'spec_helper'

describe 'kvm_automation_tooling::generate_terraform_vm_spec_set' do
  let(:cluster_id) { 'test' }
  let(:vm_specs) do
    [
      {
        'role' => 'primary',
        'os' => 'ubuntu',
        'os_version' => '24.04',
        'os_arch' => 'x86_64',
        'cpus' => 4,
        'mem_mb' => 4096,
        'disk_gb' => 20,
      },
      {
        'role' => 'agent',
        'count' => 2,
        'os' => 'ubuntu',
        'os_version' => '22.04',
        'os_arch' => 'x86_64',
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
        'platform' => 'ubuntu-2204-amd64',
        'base_image_url' => 'http://example-rspec/jammy-server.img',
        'base_volume_name' => 'jammy-server.img',
        'pool_name' => 'ubuntu-2204-amd64.pool',
        'pool_path' => 'ubuntu-2204-amd64',
      },
    ]
  end

  it 'returns a hash of per vm terraform objects keyed by hostname' do
    is_expected.to(
      run.with_params(cluster_id, vm_specs, image_results)
        .and_return(
          {
            'test-primary-1' => {
              'cpus' => 4,
              'mem_mb' => 4096,
              'disk_gb' => 20,
              'base_volume_name' => 'noble-server.img',
              'pool_name' => 'ubuntu-2404-amd64.pool',
            },
            'test-agent-1' => {
              'base_volume_name' => 'jammy-server.img',
              'pool_name' => 'ubuntu-2204-amd64.pool',
            },
            'test-agent-2' => {
              'base_volume_name' => 'jammy-server.img',
              'pool_name' => 'ubuntu-2204-amd64.pool',
            },
          }
        )
    )
  end
end
