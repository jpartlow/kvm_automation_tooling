require 'spec_helper'

describe 'kvm_automation_tooling::get_os_version_name' do
  it 'returns a version name string' do
    is_expected.to(
      run.with_params('ubuntu', '2404')
        .and_return('noble')
    )
  end

  it 'removes delimeters from ubuntu version strings' do
    is_expected.to(
      run.with_params('ubuntu', '22.04')
        .and_return('jammy')
    )
  end

  it 'returns nil for unknown ubuntu version' do
    is_expected.to(
      run.with_params('ubuntu', '9999')
        .and_return(nil)
    )
  end

  it 'returns a debian codename' do
    is_expected.to(
      run.with_params('debian', '10')
        .and_return('buster')
    )
  end

  it 'returns nil for an unknown debian codename' do
    is_expected.to(
      run.with_params('debian', '9999')
        .and_return(nil)
    )
  end
end
