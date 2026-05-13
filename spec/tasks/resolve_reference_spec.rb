require 'spec_helper'

require_relative '../../tasks/resolve_reference'

describe 'task: resolve_reference' do
  let(:task) { ResolveReference.new }
  let(:tfstate_content) do
    {
      'outputs' => {
        'vmdomain_details' => {
          'value' => {
            'agent1' => {
              'ip_addresses' => ['192.168.0.12'],
              'platform'     => 'ubuntu-2404-amd64',
              'role'         => 'agent',
            },
            'agent2' => {
              'ip_addresses' => ['192.168.0.13'],
              'platform'     => 'ubuntu-2404-amd64',
              'role'         => 'agent',
            },
            'primary1' => {
              'ip_addresses' => ['192.168.0.14'],
              'platform'     => 'ubuntu-2404-amd64',
              'role'         => 'primary',
            },
          },
        },
      },
    }
  end
  let(:tmpdir) { Dir.mktmpdir('kat.resolve_reference_spec') }
  let(:statefile_path) { File.join(tmpdir, 'tfstate.json') }
  let(:kwargs) do
    {
      dir: tmpdir,
      statefile: 'tfstate.json',
      role: 'agent',
    }
  end
  let(:refs) do
    [
      {
        'name' => 'agent1',
        'uri'  => '192.168.0.12',
        'vars' => { 'platform' => 'ubuntu-2404-amd64' },
      },
      {
        'name' => 'agent2',
        'uri'  => '192.168.0.13',
        'vars' => { 'platform' => 'ubuntu-2404-amd64' },
      },
    ]
  end

  around(:each) do |example|
    File.write(statefile_path, JSON.dump(tfstate_content))
    example.run
  ensure
    FileUtils.remove_entry(tmpdir)
  end

  describe '#load_statefile' do
    it 'loads and parses a tfstate file' do
      tfstate = task.load_statefile(dir: tmpdir, statefile: 'tfstate.json')
      expect(tfstate).to match(tfstate_content)
    end

    it 'returns an empty tfstate file if file does not exist' do
      tfstate = task.load_statefile(dir: tmpdir, statefile: 'nonexistent.json')
      expect(tfstate).to eq({})
    end

    it 'raises an error if tfstate file is invalid' do
      File.write(statefile_path, 'invalid json')
      expect {
        task.load_statefile(dir: tmpdir, statefile: 'tfstate.json')
      }.to raise_error(TaskHelper::Error, /Failed to load tfstate file/)
    end
  end

  describe '#resolve_targets' do
    it 'resolves references from tfstate' do
      expect(task).to(
        receive(:load_statefile)
          .with(dir: kwargs[:dir], statefile: kwargs[:statefile])
          .and_return(tfstate_content)
      )
      expect(task.resolve_targets(**kwargs)).to match(refs)
    end

    it 'returns an empty array if vmdomain_details output variable is not present' do
      expect(task).to receive(:load_statefile).and_return({ 'outputs' => {} })
      expect(task.resolve_targets(**kwargs)).to eq([])
    end

    it 'returns an empty array if role extracts no vms from vmdomain_details' do
      expect(task).to receive(:load_statefile).and_return(tfstate_content)
      expect(task.resolve_targets(**kwargs.merge(role: 'nonexistent'))).to eq([])
    end

    it 'prefers ipv4 addresses when selecting a URI' do
      tfstate_content['outputs']['vmdomain_details']['value']['primary1']['ip_addresses'] = ['2001:0db8:85a3:0000:0000:8a2e:1370:7334', '192.168.1.200']
      expect(task).to receive(:load_statefile).and_return(tfstate_content)
      kwargs[:role] = 'primary'
      expect(task.resolve_targets(**kwargs)).to match([
        {
          'name' => 'primary1',
          'uri'  => '192.168.1.200',
          'vars' => { 'platform' => 'ubuntu-2404-amd64' },
        },
      ])
    end

    it 'falls back to the first IP address if no valid IPv4 addresses are found' do
      ipv6 = '2001:0db8:85a3:0000:0000:8a2e:1370:7334'
      tfstate_content['outputs']['vmdomain_details']['value']['primary1']['ip_addresses'] = [ipv6]
      expect(task).to receive(:load_statefile).and_return(tfstate_content)
      kwargs[:role] = 'primary'
      expect(task.resolve_targets(**kwargs)).to match([
        {
          'name' => 'primary1',
          'uri'  => ipv6,
          'vars' => { 'platform' => 'ubuntu-2404-amd64' },
        },
      ])
    end

    it 'falls back to first ip_addresses entry if nothing is an ip address' do
      tfstate_content['outputs']['vmdomain_details']['value']['primary1']['ip_addresses'] = ['notanip']
      expect(task).to receive(:load_statefile).and_return(tfstate_content)
      kwargs[:role] = 'primary'
      expect(task.resolve_targets(**kwargs)).to match([
        {
          'name' => 'primary1',
          'uri'  => 'notanip',
          'vars' => { 'platform' => 'ubuntu-2404-amd64' },
        },
      ])
    end

    it 'handles missing ip addresses gracefully' do
      tfstate_content['outputs']['vmdomain_details']['value']['primary1'].delete('ip_addresses')
      expect(task).to receive(:load_statefile).and_return(tfstate_content)
      kwargs[:role] = 'primary'
      expect(task.resolve_targets(**kwargs)).to match([
        {
          'name' => 'primary1',
          'uri'  => nil,
          'vars' => { 'platform' => 'ubuntu-2404-amd64' },
        },
      ])
    end

  end

  it 'resolves references from a statefile on disk' do
    expect(task.task(**kwargs)).to match({ value: refs })
  end
end
