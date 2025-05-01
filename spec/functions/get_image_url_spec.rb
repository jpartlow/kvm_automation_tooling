require 'spec_helper'

describe 'kvm_automation_tooling::get_image_url' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context do
      example.run
    end
  end

  it 'uses image_url_override if given' do
    p = {
      'name'    => 'ubuntu',
      'version' => '2404',
      'arch'    => 'amd64',
      'image_url_override' => 'https://foo.rspec/override.img'
    }
    is_expected.to(
      run.with_params(p)
        .and_return('https://foo.rspec/override.img')
    )
  end

  context 'ubuntu' do
    let(:params) do
      {
        'name' => 'ubuntu',
        'version' => '2404',
        'arch' => 'amd64',
      }
    end

    it 'returns an url string for ubuntu' do
      is_expected.to(
        run.with_params(params)
          .and_return('https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img')
      )
    end

    it 'returns a daily version for ubuntu' do
      p = params.merge('image_version' => '20250425')
      is_expected.to(
        run.with_params(p)
          .and_return('https://cloud-images.ubuntu.com/noble/20250425/noble-server-cloudimg-amd64.img')

      )
    end
  end

  context 'debian' do
    let(:params) do
      {
        'name' => 'debian',
        'version' => '12',
        'arch' => 'x86_64',
      }
    end

    it 'returns an url string for debian' do
      is_expected.to(
        run.with_params(params)
          .and_return('https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2')
      )
    end

    it 'returns a historical version for debian' do
      p = params.merge('image_version' => '20240703-1797')
      is_expected.to(
        run.with_params(p)
          .and_return('https://cloud.debian.org/images/cloud/bookworm/20240703-1797/debian-12-generic-amd64-20240703-1797.qcow2')
      )
    end

    it 'returns a historical daily version for debian' do
      p = params.merge('image_version' => 'daily-20240703-1797')
      is_expected.to(
        run.with_params(p)
        .and_return('https://cloud.debian.org/images/cloud/bookworm/daily/20240703-1797/debian-12-generic-amd64-daily-20240703-1797.qcow2')
      )
    end

    it 'returns a daily latest version for debian' do
      p = params.merge(
        'version' => '13',
        'image_version' => 'daily-latest'
      )
      is_expected.to(
        run.with_params(p)
          .and_return('https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2')
      )
    end

    it 'returns a specific pre-release version for debian' do
      p = params.merge(
        'version' => '13',
        'image_version' => 'daily-20250430-2098',
      )
      is_expected.to(
        run.with_params(p)
          .and_return('https://cloud.debian.org/images/cloud/trixie/daily/20250430-2098/debian-13-generic-amd64-daily-20250430-2098.qcow2')
      )
    end
  end
end
