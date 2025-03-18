require 'spec_helper'

describe 'kvm_automation_tooling::get_image_url' do
  it 'returns an url string' do
    is_expected.to(
      run.with_params('ubuntu-2404-amd64')
        .and_return('https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img')
    )
  end
end
