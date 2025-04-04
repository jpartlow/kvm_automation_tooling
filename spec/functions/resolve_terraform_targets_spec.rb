require 'spec_helper'

describe 'kvm_automation_tooling::resolve_terraform_targets' do
  include BoltSpec::BoltContext

  let(:tempdir) { Dir.mktmpdir('rspec-kat-resolve-terraform-targets') }

  # Mock out functions coming from other Bolt modules
  let(:pre_cond) do
    <<~PRECOND
      function resolve_references(Hash $group) {
        {
          'targets' => [
            {
              'name' => 'spec-primary-1',
              'uri'  => '192.168.100.100',
            },
            {
              'name' => 'spec-agent-1',
              'uri'  => '192.168.100.200',
            },
          ],
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
          - name: puppet
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
      result = call_function('kvm_automation_tooling::resolve_terraform_targets', "#{tempdir}/inventory-spec.yaml", 'primary')
      expect(result).to match_array(
        have_attributes(
          name: 'spec-primary-1.some.domain',
          uri: '192.168.100.100',
          user: 'spec',
          vars: {},
          config: {'ssh' => {'user' => 'spec', 'run-as' => 'root'}},
        )
      )
    end

    context 'but no matching targets' do
      it 'returns an empty array' do
        is_expected.to run.with_params("#{tempdir}/inventory-spec.yaml", 'notfound').and_return([])
      end
    end

    context 'that is empty' do
      let(:inventory_yaml) { '' }

      it 'raises an error the group is not in the inventory file' do
        is_expected.to(
          run.with_params('/non_existent_file.yaml', 'primary')
            .and_raise_error(%r{Did not find group 'puppet' in inventory})
        )
      end
    end
  end

  it 'raises an error if there is no inventory file' do
    is_expected.to(
      run.with_params('/non_existent_file.yaml', 'primary')
        .and_raise_error(%r{Did not find group 'puppet' in inventory})
    )
  end
end
