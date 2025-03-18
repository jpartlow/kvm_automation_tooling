require 'spec_helper'

describe 'kvm_automation_tooling::get_normalized_ubuntu_version' do
  it 'removes delimeters from an ubuntu version string' do
    is_expected.to(run.with_params('24.04').and_return('2404'))
  end

  it 'returns the string unchanged if it does not contain delimeters' do
    is_expected.to(run.with_params('2404').and_return('2404'))
  end
end
