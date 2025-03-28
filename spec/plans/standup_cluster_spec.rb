require 'spec_helper'
require 'tmpdir'

describe 'plan: standup_cluster' do
  include_context 'plan_init'

  let(:tempdir) { Dir.mktmpdir('rspec-kat') }
  let(:params) do
    {
      'cluster_name' => 'spec',
      'os'           => 'ubuntu',
      'os_version'   => '24.04',
      'os_arch'      => 'x86_64',
      'network_addresses'   => '192.168.100.0/24',
      'terraform_state_dir' => tempdir,
      'image_download_dir'  => '/dev/null',
    }
  end
  let(:cluster_id) { 'spec-singular-ubuntu-2404-amd64' }

  around(:each) do |example|
    example.run
  ensure
    FileUtils.remove_entry_secure(tempdir)
  end

  before(:each) do
    # Provide
    FileUtils.cp(File.join(KatRspec.fixture_path, '/terraform/spec.tfstate'), "#{tempdir}/#{cluster_id}.tfstate")
  end

  it 'should run successfully' do
    allow_any_out_message

    expect_command("mkdir -p /dev/null")
      .with_targets('localhost')
    expect_task('kvm_automation_tooling::download_image')
    expect_task('kvm_automation_tooling::import_libvirt_volume')
    expect_task('kvm_automation_tooling::create_libvirt_image_pool')
    expect_task('terraform::initialize')
    expect_plan('terraform::apply')
      .with_params(
        'dir'           => './terraform',
        'var_file'      => "#{tempdir}/#{cluster_id}.tfvars.json",
        'state'         => "#{tempdir}/#{cluster_id}.tfstate",
        'return_output' => true,
      )
    allow_apply_prep

    result = run_plan('kvm_automation_tooling::standup_cluster', params)
    expect(result.ok?).to(eq(true), result.value)
  end
end
