require 'spec_helper'

describe 'kvm_automation_tooling::platform' do
  it 'returns a platform string' do
    is_expected.to(
      run.with_params('ubuntu', '2204', 'amd64')
        .and_return('ubuntu-2204-amd64')
    )
  end

  it 'removes delimeters from ubuntu version strings' do
    is_expected.to(
      run.with_params('ubuntu', '22.04', 'amd64')
        .and_return('ubuntu-2204-amd64')
    )
  end

  it 'switches to amd64 for ubuntu arch' do
    is_expected.to(
      run.with_params('ubuntu', '2204', 'x86_64')
        .and_return('ubuntu-2204-amd64')
    )
  end
end
