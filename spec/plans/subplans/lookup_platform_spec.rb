require 'spec_helper'

describe 'plan: kvm_automation_tooling::subplans::lookup_platform' do
  include_context 'plan_init'

  let(:facts) do
    {
      'os' => {
        'name' => 'Ubuntu',
        'release' => {
          'full' => '24.04',
          'major' => '24',
          'minor' => '04',
        },
      },
    }
  end

  def inventory_data
    {
      'facts' => facts,
      'targets' => [
        'spec',
      ],
    }
  end

  before(:each) do
    expect_task('facts').with_targets('spec').always_return({})
  end

  it 'returns a target with platform var set' do
    expect_command('uname -m').with_targets('spec').always_return('stdout' => "x86_64\n")

    result = run_plan('kvm_automation_tooling::subplans::lookup_platform', 'targets' => 'spec')

    expect(result.ok?).to(eq(true), result.value.to_s)
    expect(result.value.first.vars).to include(
      'platform' => 'ubuntu-2404-amd64',
    )
  end

  context 'when facter is present' do
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

    it 'returns a target with platform var set without a separate uname lookup' do
      result = run_plan('kvm_automation_tooling::subplans::lookup_platform', 'targets' => 'spec')

      expect(result.ok?).to(eq(true), result.value.to_s)
      expect(result.value.first.vars).to include(
        'platform' => 'ubuntu-2404-amd64',
      )
    end
  end

  context 'debian pre-release image' do
    let(:facts) do
      {
        'os' => {
          'name' => 'Debian',
          'release' => {
            'full' => 'trixie/sid',
            'major' => 'trixie/sid',
          },
          'distro' => {
            'codename' => 'trixie',
          },
          'architecture' => 'amd64',
        },
      }
    end

    it 'returns a target with platform var by translating codename' do
      result = run_plan('kvm_automation_tooling::subplans::lookup_platform', 'targets' => 'spec')

      expect(result.ok?).to(eq(true), result.value.to_s)
      expect(result.value.first.vars).to include(
        'platform' => 'debian-13-amd64',
      )
    end

  end
end
