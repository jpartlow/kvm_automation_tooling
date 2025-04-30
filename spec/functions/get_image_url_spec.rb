require 'spec_helper'

describe 'kvm_automation_tooling::get_image_url' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context do
      example.run
    end
  end

  it 'uses image_url_override if given' do
    is_expected.to(
      run.with_params('ubuntu-2404-amd64', 'image_url_override' => 'https://foo.rspec/override.img')
        .and_return('https://foo.rspec/override.img')
    )
  end

  it 'returns an url string for ubuntu' do
    is_expected.to(
      run.with_params('ubuntu-2404-amd64')
        .and_return('https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img')
    )
  end

  it 'returns a daily version for ubuntu' do
    is_expected.to(
      run.with_params('ubuntu-2404-amd64', 'image_version' => '20250425')
        .and_return('https://cloud-images.ubuntu.com/noble/20250425/noble-server-cloudimg-amd64.img')

    )
  end

  it 'returns an url string for debian' do
    is_expected.to(
      run.with_params('debian-12-amd64')
      .and_return('https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2')
    )
  end

  it 'returns a historical version for debian' do
    is_expected.to(
      run.with_params('debian-10-amd64', 'image_version' => '20240703-1797')
      .and_return('https://cloud.debian.org/images/cloud/buster/20240703-1797/debian-10-generic-amd64-20240703-1797.qcow2')
    )
  end

  it 'returns a historical daily version for debian' do
    is_expected.to(
      run.with_params('debian-10-amd64', 'image_version' => 'daily-20240703-1797')
      .and_return('https://cloud.debian.org/images/cloud/buster/daily/20240703-1797/debian-10-generic-amd64-daily-20240703-1797.qcow2')
    )
  end

  it 'returns a daily latest version for debian' do
    is_expected.to(
      run.with_params('debian-13-amd64', 'image_version' => 'daily-latest')
      .and_return('https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2')
    )
  end

  it 'returns a specific pre-release version for debian' do
    is_expected.to(
      run.with_params('debian-13-amd64', 'image_version' => 'daily-20250430-2098')
      .and_return('https://cloud.debian.org/images/cloud/trixie/daily/20250430-2098/debian-13-generic-amd64-daily-20250430-2098.qcow2')
    )
  end
end
