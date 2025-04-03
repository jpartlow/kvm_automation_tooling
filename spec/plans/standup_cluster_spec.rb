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
      'vms' => [
        {
          'role' => 'primary',
          'cpus' => 2,
          'mem_mb' => 2048,
          'disk_gb' => 20,
        },
      ],
    }
  end
  let(:cluster_id) { 'spec-singular-ubuntu-2404-amd64' }

  around(:each) do |example|
    example.run
  ensure
    FileUtils.remove_entry_secure(tempdir)
  end

  before(:each) do
    # Provide a terraform state file for inventory to resolve from.
    FileUtils.cp(File.join(KatRspec.fixture_path, '/terraform/spec.tfstate'), "#{tempdir}/#{cluster_id}.tfstate")
  end

  context 'successfully runs' do

    before(:each) do
      allow_any_out_message

      expect_task('terraform::initialize')
      expect_plan('terraform::apply')
        .with_params(
          'dir'           => './terraform',
          'var_file'      => "#{tempdir}/#{cluster_id}.tfvars.json",
          'state'         => "#{tempdir}/#{cluster_id}.tfstate",
          'return_output' => true,
        )
    end

    context 'for a single platform' do
      before(:each) do
        expect_command("mkdir -p /dev/null")
          .with_targets('localhost')
        expect_task('kvm_automation_tooling::download_image')
        expect_task('kvm_automation_tooling::import_libvirt_volume')
        expect_task('kvm_automation_tooling::create_libvirt_image_pool')
      end

      it 'terraforms and installs openvox' do
        allow_apply_prep

        result = run_plan('kvm_automation_tooling::standup_cluster', params)
        expect(result.ok?).to(eq(true), result.value)
      end

      it 'just terraforms when install_openvox is false' do
        params['install_openvox'] = false
        result = run_plan('kvm_automation_tooling::standup_cluster', params)
        expect(result.ok?).to(eq(true), result.value)
      end
    end

    context 'with multiple vm platforms' do
      before(:each) do
        expect_command("mkdir -p /dev/null")
          .with_targets('localhost')
          .be_called_times(2)

        # Expect ubuntu 24.04
        expect_task('kvm_automation_tooling::download_image')
          .with_params(
            'image_url' => 'https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img',
            'download_dir' => '/dev/null',
          )
        expect_task('kvm_automation_tooling::import_libvirt_volume')
          .with_params(
            'image_path' => '/dev/null/noble-server-cloudimg-amd64.img',
            'volume_name' => 'noble-server-cloudimg-amd64.img',
          )
        expect_task('kvm_automation_tooling::create_libvirt_image_pool')
          .with_params(
            'name' => 'ubuntu-2404-amd64.pool',
            'path' => 'ubuntu-2404-amd64',
          )

        # And expect ubuntu 22.04
        expect_task('kvm_automation_tooling::download_image')
          .with_params(
            'image_url' => 'https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img',
            'download_dir' => '/dev/null',
          )
        expect_task('kvm_automation_tooling::import_libvirt_volume')
          .with_params(
            'image_path' => '/dev/null/jammy-server-cloudimg-amd64.img',
            'volume_name' => 'jammy-server-cloudimg-amd64.img',
          )
        expect_task('kvm_automation_tooling::create_libvirt_image_pool')
          .with_params(
            'name' => 'ubuntu-2204-amd64.pool',
            'path' => 'ubuntu-2204-amd64',
          )

        allow_apply_prep
      end

      it 'manages all platforms' do
        params['vms'] << {
          'role' => 'agent',
          'os' => 'ubuntu',
          'os_version' => '22.04',
          'os_arch' => 'x86_64',
        }
        result = run_plan('kvm_automation_tooling::standup_cluster', params)
        expect(result.ok?).to(eq(true), result.value)
      end
    end
  end
end
