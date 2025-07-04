require 'spec_helper'
include RspecPuppetFacts

describe 'kvm_automation_tooling::server::package_prerequisites' do
  let(:el_prereqs) do
    [
      'java-17-openjdk-headless',
      'net-tools',
      'procps-ng',
      'which',
    ]
  end
  let(:debian_prereqs) do
    [
      'openjdk-17-jre-headless',
      'net-tools',
      'procps',
    ]
  end
  let(:debian10_prereqs) do
    [
      'openjdk-11-jre-headless',
      'net-tools',
      'procps',
    ]
  end
  let(:debian13_prereqs) do
    [
      'openjdk-21-jre-headless',
      'net-tools',
      'procps',
    ]
  end

  let(:prereqs) do
    {
      'redhat-8-x86_64'  => el_prereqs,
      'redhat-9-x86_64'  => el_prereqs,
      'debian-10-x86_64' => debian10_prereqs,
      'debian-11-x86_64' => debian_prereqs,
      'debian-12-x86_64' => debian_prereqs,
    }
  end

  test_on = {
    supported_os: [
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => ['8', '9'],
      },
      {
        'operatingsystem'        => 'Debian',
        'operatingsystemrelease' => ['11', '12'],
      },
    ],
  }

  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
          os_facts
      end

      it "installs correct prerequisite packages" do
        is_expected.to contain_package(*prereqs[os]).with_ensure('present')
      end
    end
  end

  # facterdb 3.8 no longer supports debian 10
  context 'debian 10' do
    let(:facts) do
      {
        'os' => {
          'family'  => 'Debian',
          'release' => { 'major' => '10' },
        },
        # there are warnings with out these stubs for facts prodded
        # by the compiler, most likely
        'networking' => { 'ip' => {}, 'fqdn' => '' },
      }
    end

    it "installs correct prerequisite packages" do
      is_expected.to contain_package(*debian10_prereqs).with_ensure('present')
    end
  end

  # facterdb 3.8 does not yet support debian 13
  context 'debian 13' do
    let(:facts) do
      {
        'os' => {
          'family'  => 'Debian',
          'release' => { 'major' => '13'},
        },
        # there are warnings with out these stubs for facts prodded
        # by the compiler, most likely
        'networking' => { 'ip' => {}, 'fqdn' => '' },
      }
    end

    it "installs correct prerequisite packages" do
      is_expected.to contain_package(*debian13_prereqs).with_ensure('present')
    end
  end
end
