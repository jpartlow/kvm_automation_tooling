require 'spec_helper'

describe 'plan: subplans::manage_base_image_volume' do
  include_context 'plan_init'

  let(:params) do
    {
      'platform' => 'ubuntu-2404-amd64',
      'image_download_dir' => '/dev/null',
    }
  end

  it 'should run successfully' do
    expect_command("mkdir -p /dev/null")
      .with_targets('localhost')
    expect_task('kvm_automation_tooling::download_image')
      .with_targets('localhost')
      .with_params(
        'image_url'    => 'https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img',
        'download_dir' => '/dev/null',
      )
    expect_task('kvm_automation_tooling::import_libvirt_volume')
      .with_targets('localhost')
      .with_params(
        'image_path'  => '/dev/null/noble-server-cloudimg-amd64.img',
        'volume_name' => 'noble-server-cloudimg-amd64.img',
      )
    expect_task('kvm_automation_tooling::create_libvirt_image_pool')
      .with_targets('localhost')
      .with_params(
        'name' => 'ubuntu-2404-amd64.pool',
      )

    result = run_plan('kvm_automation_tooling::subplans::manage_base_image_volume', params)
    expect(result.ok?).to eq(true)
  end
end
