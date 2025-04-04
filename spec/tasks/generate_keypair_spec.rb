require 'spec_helper'

require_relative '../../tasks/generate_keypair'

describe 'task: generate_keypair.rb' do
  let(:task) { GenerateKeypair.new }
  let(:success) { instance_double(Process::Status, success?: true, exitstatus: 0) }

  it 'generates a keypair' do
    expect(Dir).to receive(:mktmpdir).and_return('/tmp/kat-generate-keypair')
    expect(Open3).to(
      receive('capture2e')
        .with('ssh-keygen', '-t', 'ed25519', '-f', '/tmp/kat-generate-keypair/id_ed25519', '-N', '')
        .and_return(['output', success])
    )
    expect(File).to receive(:read).with('/tmp/kat-generate-keypair/id_ed25519.pub').and_return('public key')

    expect(task.task(type: 'ed25519')).to include(
      {
        tmpdir: '/tmp/kat-generate-keypair',
        keyfile: 'id_ed25519',
        pubkeyfile: 'id_ed25519.pub',
        pubkey: 'public key',
      }
    )
  end
end
