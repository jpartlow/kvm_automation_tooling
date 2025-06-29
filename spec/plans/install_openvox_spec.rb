require 'spec_helper'

describe 'plan: install_openvox' do
  include_context 'plan_init'

  def make_target(name)
    Bolt::Target.from_hash({'name' => name}, inventory)
  end

  let(:inventory) { Bolt::Inventory.empty }
  let(:all_targets) { [ make_target('agent-1.rspec') ] }
  let(:params) do
    {
      'openvox_agent_targets' => all_targets,
    }
  end

  before(:each) do
    allow_out_message
    expect_plan('facts')
      .with_params('targets' => all_targets)
  end

  it 'installs latest agent on targets' do
    expect_task('openvox_bootstrap::install')
      .with_targets(all_targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => 'latest',
        'collection' => 'openvox8',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
      })
    expect_task('package')
      .with_targets(all_targets)
      .always_return({
        'status' => 'installed',
        'version' => '8.0.0',
      })


    result = run_plan('kvm_automation_tooling::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)

    version_map = result.value
    expect(version_map).to eq({
      'agent-1.rspec' => {
        'openvox-agent' => '8.0.0',
      }
    })
  end

  it 'installs specific agent on targets' do
    params['openvox_agent_params'] = {
      'openvox_version'  => '7.0.0',
    }

    expect_task('openvox_bootstrap::install')
      .with_targets(all_targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => '7.0.0',
        'collection' => 'openvox7',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
      })
    expect_task('package')

    result = run_plan('kvm_automation_tooling::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs a pre-release build on targets' do
    params['openvox_agent_params'] = {
      'openvox_version'  => '9.0.0',
      'openvox_released' => false,
    }

    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(all_targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://artifacts.voxpupuli.org',
      })
    expect_task('package')

    result = run_plan('kvm_automation_tooling::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs from a different artifacts_source' do
    params['openvox_agent_params'] = {
      'openvox_version' => '9.0.0',
      'openvox_released' => false,
      'openvox_artifacts_url' => 'https://some.other',
    }

    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(all_targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://some.other',
      })
    expect_task('package')

    result = run_plan('kvm_automation_tooling::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  context 'with primary targets' do
    let(:agent_targets) { [ make_target('agent-1.rspec') ] }
    let(:primary_targets) { [ make_target('primary-1.rspec') ] }
    let(:all_targets) { agent_targets + primary_targets }
    let(:params) do
      {
        'openvox_agent_targets'  => agent_targets,
        'openvox_server_targets' => primary_targets,
        'openvox_db_targets'     => primary_targets,
      }
    end

    before(:each) do
    end

    it 'installs latest agent and server packages to targets' do
      expect_task('openvox_bootstrap::install')
        .with_targets(all_targets)
        .with_params({
          'package'    => 'openvox-agent',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvox-server',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
        })
      expect_task('package')
        .with_targets(all_targets)
        .always_return({
          'status' => 'installed',
          'version' => '8.0.0',
        })
      expect_task('package')
        .with_targets(primary_targets)
        .with_params({
          'name'   => 'openvox-server',
          'action' => 'status',
        })
        .always_return({
          'status' => 'installed',
          'version' => '8.1.0',
        })
      expect_task('package')
        .with_targets(primary_targets)
        .with_params({
          'name'   => 'openvoxdb',
          'action' => 'status',
        })
        .always_return({
          'status' => 'installed',
          'version' => '8.2.0',
        })

      result = run_plan('kvm_automation_tooling::install_openvox', params)
      expect(result.ok?).to(eq(true), result.value.to_s)

      version_map = result.value
      expect(version_map).to eq({
        'agent-1.rspec' => {
          'openvox-agent' => '8.0.0',
        },
        'primary-1.rspec' => {
          'openvox-agent'  => '8.0.0',
          'openvox-server' => '8.1.0',
          'openvoxdb'      => '8.2.0',
        }
      })
    end

    it 'installs specific agent and server packages to targets' do
      params['openvox_server_params'] = {
        'openvox_version'  => '9.0.0',
        'openvox_released' => false,
      }

      expect_task('openvox_bootstrap::install')
        .with_targets(all_targets)
        .with_params({
          'package'    => 'openvox-agent',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
        })
      expect_task('openvox_bootstrap::install_build_artifact')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvox-server',
          'version'    => '9.0.0',
          'artifacts_source' => 'https://artifacts.voxpupuli.org',
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
        })
      expect_task('package').be_called_times(3)

      result = run_plan('kvm_automation_tooling::install_openvox', params)
      expect(result.ok?).to(eq(true), result.value.to_s)
    end
  end
end
