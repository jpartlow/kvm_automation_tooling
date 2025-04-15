require 'spec_helper'
require 'tmpdir'

describe 'plan: standup_cluster' do
  include_context 'plan_init'

  let(:tempdir) { Dir.mktmpdir('rspec-kat-standup-cluster') }
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
        {
          'role' => 'agent',
        }
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

  context 'with bad parameters' do
    it 'raises if os params partially set' do
      params.delete('os_version')
      result = run_plan('kvm_automation_tooling::standup_cluster', params)
      expect(result.ok?).to eq(false)
      expect(result.value.msg).to match(/os_version.*must all be set/)
    end

    it 'raises if os params not set and vms do not all have os params' do
      params.delete('os')
      params.delete('os_version')
      params.delete('os_arch')

      result = run_plan('kvm_automation_tooling::standup_cluster', params)
      expect(result.ok?).to eq(false)
      expect(result.value.msg).to match(/os_version.*must be set if not set in the vm spec hashes/)
    end

    it 'raises if os params unset and only some vms have os params' do
      params.delete('os')
      params.delete('os_version')
      params.delete('os_arch')
      params['vms'] = [
        {
          'role' => 'primary',
        },
        {
          'role' => 'agents',
          'os'         => 'ubuntu',
          'os_version' => '24.04',
          'os_arch'    => 'x86_64',
        },
      ]

      result = run_plan('kvm_automation_tooling::standup_cluster', params)
      expect(result.ok?).to eq(false)
      expect(result.value.msg).to match(/os_version.*must be set if not set in the vm spec hashes/)
    end
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
      expect_plan('kvm_automation_tooling::subplans::setup_cluster_ssh')
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
        expect(result.ok?).to(eq(true), result.value.to_s)

        target_map = result.value
        expect(target_map.keys).to match_array(['primary', 'agent'])
        expect(target_map['primary'].map(&:name)).to eq(["spec-singular-ubuntu-2404-amd64-primary-1.vm"])
        expect(target_map['agent'].map(&:name)).to eq(["spec-singular-ubuntu-2404-amd64-agent-1.vm"])
      end

      it 'just terraforms when install_openvox is false' do
        params['install_openvox'] = false
        result = run_plan('kvm_automation_tooling::standup_cluster', params)
        expect(result.ok?).to(eq(true), result.value.to_s)
      end

      it 'adds host root access when requsted' do
        allow_apply_prep

        public_key_path = "#{tempdir}/ssh_rspec.pub"
        File.write(public_key_path, 'rspec-public-key')
        params['ssh_public_key_path'] = public_key_path
        params['host_root_access'] = true
        expect_task('kvm_automation_tooling::add_ssh_authorized_key')
          .with_targets(['spec-singular-ubuntu-2404-amd64-primary-1.vm', 'spec-singular-ubuntu-2404-amd64-agent-1.vm'])
          .with_params({
            'user' => 'root',
            'ssh_public_key' => 'rspec-public-key',
          })

        result = run_plan('kvm_automation_tooling::standup_cluster', params)
        expect(result.ok?).to(eq(true), result.value.to_s)
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
        expect(result.ok?).to(eq(true), result.value.to_s)
      end
    end
  end
end
