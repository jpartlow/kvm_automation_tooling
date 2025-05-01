require 'spec_helper'

describe 'plan: kvm_automation_tooling::dev::generate_beaker_hosts_file' do
  include_context 'plan_init'

  let(:tmpdir) { Dir.mktmpdir('kat-generate_beaker_hosts_file') }
  let(:facts) do
    {
      'os' => {
        'name' => 'Ubuntu',
        'release' => {
          'full' => '24.04',
          'major' => '24',
          'minor' => '04',
        },
        'architecture' => 'x86_64',
      },
    }
  end
  let(:hosts_yaml) { File.join(tmpdir, 'hosts.yaml') }

  around(:each) do |example|
    example.run
  ensure
    FileUtils.remove_entry_secure(tmpdir)
  end

  before(:each) do
    expect_task('facts').with_targets('spec').always_return(facts)
  end

  it 'generates a valid beaker hosts file' do
    result = run_plan(
      'kvm_automation_tooling::dev::generate_beaker_hosts_file',
      'hosts'      => 'spec',
      'hosts_yaml' => hosts_yaml
    )
    expect(result.ok?).to(eq(true), result.value.to_s)

    hosts_hash = YAML.load_file(hosts_yaml)

    expect(hosts_hash).to match({
      'HOSTS' => {
        'spec' => {
          'vmhostname' => 'spec.vm',
          'ip' => 'spec',
          'roles' => ['agent'],
          'platform' => 'ubuntu-2404-amd64',
          'hypervisor' => 'none',
        },
      },
      'CONFIG' => {
        'forge_host' => nil,
      },
    })
  end
end
