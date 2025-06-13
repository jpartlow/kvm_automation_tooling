require 'spec_helper'

describe 'kvm_automation_tooling::resolve_terraform_targets' do
  include BoltSpec::BoltContext

  let(:tempdir) { Dir.mktmpdir('rspec-kat-resolve-terraform-targets') }
  let(:targets) do
    [
      {
        'name' => 'spec-agent-1',
        'uri'  => '192.168.100.200',
        'vars' => {'platform' => 'ubuntu'},
      },
    ]
  end

  # Mock out functions coming from other Bolt modules
  let(:pre_cond) do
    <<~PRECOND
      function resolve_references(Hash $group) {
        {
          'targets' => #{targets}
        }
      }
    PRECOND
  end

  around(:each) do |example|
    in_bolt_context do
      example.run
    end
  ensure
    FileUtils.remove_entry_secure(tempdir)
  end

  context 'with an inventory file' do
    let(:inventory_yaml) do
      <<~YAML
        ---
        groups:
          - name: agent
            vars:
              domain_name: some.domain
            targets:
              _plugin: terraform
              dir: #{tempdir}
              state: #{tempdir}/spec.tfstate
            resource_type: libvirt_domain.domain
            target_mapping:
              name: network_interface.0.hostname
              uri: network_interface.0.addresses.0
              vars:
                platform: metadata
        config:
          ssh:
            user: spec
            run-as: root
      YAML
    end

    before(:each) do
      # Provide a terraform state file for inventory to parse.
      File.write("#{tempdir}/inventory-spec.yaml", inventory_yaml)
    end

    it 'resolves the terraform targets matching role in the given inventory file' do
      result = call_function('kvm_automation_tooling::resolve_terraform_targets', "#{tempdir}/inventory-spec.yaml", 'agent')

      expect(result.count).to eq(1)
      target = result.first
      expect(target.name).to eq('spec-agent-1')
      expect(target.uri).to eq('192.168.100.200')
      expect(target.user).to eq('spec')
      expect(target.vars).to eq({
        'domain_name' => 'some.domain',
        'platform'    => 'ubuntu',
      })
      expect(target.config).to eq({'ssh' => {'user' => 'spec', 'run-as' => 'root'}})
    end

    it 'raises an error if the group cannot be found' do
      expect do
        call_function('kvm_automation_tooling::resolve_terraform_targets', "#{tempdir}/inventory-spec.yaml", 'non_existent_group')
      end.to(raise_error(Puppet::ParseError, /Did not find group 'non_existent_group' in inventory/))
    end

    context 'but no matching targets' do
      let(:targets) { [] }

      it 'returns an empty array' do
        is_expected.to run.with_params("#{tempdir}/inventory-spec.yaml", 'agent').and_return([])
      end
    end

    context 'that is empty' do
      it 'raises an error that the group is not in the inventory file' do
        is_expected.to(
          run.with_params('/non_existent_file.yaml', 'primary')
            .and_raise_error(%r{Did not find group 'primary' in inventory})
        )
      end
    end
  end

  it 'raises an error if there is no inventory file' do
    is_expected.to(
      run.with_params('/non_existent_file.yaml', 'primary')
        .and_raise_error(%r{Did not find group 'primary' in inventory})
    )
  end
end
