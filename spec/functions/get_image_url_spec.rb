require 'spec_helper'

describe 'kvm_automation_tooling::get_image_url' do
  it 'returns an url string for ubuntu' do
    is_expected.to(
      run.with_params('ubuntu-2404-amd64')
        .and_return('https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img')
    )
  end

  it 'returns an url string for debian' do
    is_expected.to(
      run.with_params('debian-12-amd64')
      .and_return('https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2')
    )
  end
end
