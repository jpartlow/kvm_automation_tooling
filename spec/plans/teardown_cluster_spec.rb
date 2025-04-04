require 'spec_helper'

describe 'plan: teardown_cluster' do
  include_context 'plan_init'

  let(:params) do
    {
      'cluster_id' => 'spec-singular-ubuntu-2404-amd64',
    }
  end
  let(:terraform_state_dir) do
    File.join(KatRspec.fixture_path, 'modules/kvm_automation_tooling/files/../terraform/instances')
  end

  before(:each) do
    expect_plan('terraform::destroy')
      .with_params(
        'dir'       => './terraform',
        'state'     => "#{terraform_state_dir}/#{params['cluster_id']}.tfstate",
        'var_file'  => "#{terraform_state_dir}/#{params['cluster_id']}.tfvars.json",
      )
  end

  context 'with state files to delete' do
    let(:terraform_state_dir) { Dir.mktmpdir('rspec-kat-teardown-cluster') }
    let(:tfvars_file) { "#{terraform_state_dir}/#{params['cluster_id']}.tfvars.json" }
    let(:tfstate_file) { "#{terraform_state_dir}/#{params['cluster_id']}.tfstate" }
    let(:inventory_file) { "#{terraform_state_dir}/inventory.#{params['cluster_id']}.yaml" }

    around(:each) do |example|
      example.run
    ensure
      FileUtils.remove_entry_secure(terraform_state_dir)
    end

    before(:each) do
      FileUtils.touch(tfvars_file)
      FileUtils.touch(tfstate_file)
      FileUtils.touch(inventory_file)
    end

    it 'runs successfully' do
      params['terraform_state_dir'] = terraform_state_dir

      expect(run_plan('kvm_automation_tooling::teardown_cluster', params)).to be_ok
      expect(File.exist?(tfvars_file)).to(eq(false))
      expect(File.exist?(tfstate_file)).to(eq(false))
      expect(File.exist?(inventory_file)).to(eq(false))
    end
  end

  context 'with no state files to delete' do
    it 'runs successfully' do
      expect(run_plan('kvm_automation_tooling::teardown_cluster', params)).to be_ok
    end
  end
end
