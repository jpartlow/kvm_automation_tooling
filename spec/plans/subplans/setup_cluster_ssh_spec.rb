require 'spec_helper'

describe 'plan: setup_cluster_ssh' do
  include_context 'plan_init'

  let(:controllers) { ['controller1.rspec'] }
  let(:destinations) { ['agent1.rspec', 'agent2.rspec'] }
  let(:params) do
    {
      'controllers'  => controllers,
      'destinations' => destinations,
      'user'         => 'spec',
    }
  end

  it 'without controllers it does nothing' do
    params['controllers'] = []
    expect_out_message

    result = run_plan('kvm_automation_tooling::subplans::setup_cluster_ssh', params)
    expect(result.ok?).to(eq(true), result.value)
  end

  context 'with controllers' do
    # The generate_keypair task will create a temporary directory for
    # the keyfiles with a prefix of kat-generate-keypair.
    let(:tmpdir) { '/tmp/kat-generate-keypair-foo' }

    around(:each) do |example|
      # Creating the temp directory and files that upload_file will
      # source because the expect_upload function has a bug that
      # causes it to check for existence of the files.
      FileUtils.mkdir(tmpdir) unless Dir.exist?(tmpdir)
      FileUtils.touch(File.join(tmpdir, 'id_ed25519'))
      FileUtils.touch(File.join(tmpdir, 'id_ed25519.pub'))
      example.run
    ensure
      FileUtils.remove_entry_secure(tmpdir)
    end

    before(:each) do
      allow_any_out_message

      expect_task('kvm_automation_tooling::generate_keypair')
        .with_targets('localhost')
        .with_params('type' => 'ed25519')
        .always_return({
          tmpdir: '/tmp/kat-generate-keypair-foo',
          keyfile: 'id_ed25519',
          pubkeyfile: 'id_ed25519.pub',
          pubkey: 'ssh-ed25519 publickey',
        })
      expect_command("rm -rf #{tmpdir}")
        .with_targets('localhost')
    end

    it 'runs and deletes tmpdir' do
      expect_upload('/tmp/kat-generate-keypair-foo/id_ed25519')
        .with_destination('/home/spec/.ssh/id_ed25519')
        .with_targets(controllers)
      expect_upload('/tmp/kat-generate-keypair-foo/id_ed25519.pub')
        .with_destination('/home/spec/.ssh/id_ed25519.pub')
        .with_targets(controllers)
      expect_command('chown -R spec:spec /home/spec/.ssh/id_ed25519*')
        .with_targets(controllers)

      expect_task('kvm_automation_tooling::add_ssh_authorized_key')
        .with_targets(destinations)
        .with_params({
          'user' => 'spec',
          'ssh_public_key' => 'ssh-ed25519 publickey',
        })
      expect_task('kvm_automation_tooling::add_ssh_authorized_key')
        .with_targets(destinations)
        .with_params({
          'user' => 'root',
          'ssh_public_key' => 'ssh-ed25519 publickey',
        })

      result = run_plan('kvm_automation_tooling::subplans::setup_cluster_ssh', params)
      expect(result.ok?).to(eq(true), result.value)
    end

    it 'deletes tmpdir after error' do
      expect_upload('/tmp/kat-generate-keypair-foo/id_ed25519')
      expect_upload('/tmp/kat-generate-keypair-foo/id_ed25519.pub')
      expect_command('chown -R spec:spec /home/spec/.ssh/id_ed25519*')
        .error_with('kind' => 'err', 'msg' => 'oops')

      result = run_plan('kvm_automation_tooling::subplans::setup_cluster_ssh', params)
      expect(result.ok?).to eq(false)
    end
  end
end
