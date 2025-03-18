require 'spec_helper'

describe 'kvm_automation_tooling::get_ubuntu_version_name' do
  it 'returns a version name string' do
    is_expected.to(
      run.with_params('2404')
        .and_return('noble')
    )
  end

  it 'removes delimeters from ubuntu version strings' do
    is_expected.to(
      run.with_params('22.04')
        .and_return('jammy')
    )
  end

  it 'returns nil for unknown ubuntu version' do
    is_expected.to(
      run.with_params('9999')
        .and_return(nil)
    )
  end
end
