require 'spec_helper'

describe 'plan: install_openvox' do
  include_context 'plan_init'

  let(:inventory) { Bolt::Inventory.empty }
  let(:targets) do
    [
      Bolt::Target.from_hash({'name' => 'agent1.rspec'}, inventory),
    ]
  end
  let(:params) do
    {
      'targets' => targets,
    }
  end

  before(:each) do
    expect_plan('facts')
      .with_params('targets' => targets)
  end

  it 'installs latest agent on targets' do
    expect_task('openvox_bootstrap::install')
      .with_targets(targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => 'latest',
        'collection' => 'openvox8',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
      })

    result = run_plan('kvm_automation_tooling::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs specific agent on targets' do
    params['openvox_version'] = '7.0.0'
    expect_task('openvox_bootstrap::install')
      .with_targets(targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => '7.0.0',
        'collection' => 'openvox7',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
      })

    result = run_plan('kvm_automation_tooling::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs a pre-release build on targets' do
    params['openvox_version'] = '9.0.0'
    params['openvox_released'] = false
    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://artifacts.voxpupuli.org',
      })

    result = run_plan('kvm_automation_tooling::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs from a different artifacts_source' do
    params['openvox_version'] = '9.0.0'
    params['openvox_released'] = false
    params['openvox_artifacts_url'] = 'https://some.other'
    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://some.other',
      })

    result = run_plan('kvm_automation_tooling::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end
end
