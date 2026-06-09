require 'spec_helper'

describe 'kvm_automation_tooling::get_normalized_libvirt_arch' do
  it 'returns x86_64 for x86_64' do
    is_expected.to(
      run.with_params('x86_64')
        .and_return('x86_64')
    )
  end

  it 'returns aarch64 for aarch64' do
    is_expected.to(
      run.with_params('aarch64')
        .and_return('aarch64')
    )
  end

  it 'returns aarch64 for arm64' do
    is_expected.to(
      run.with_params('arm64')
        .and_return('aarch64')
    )
  end

  it 'returns x86_64 for amd64' do
    is_expected.to(
      run.with_params('amd64')
        .and_return('x86_64')
    )
  end

  it 'returns undef for undef' do
    is_expected.to(
      run.with_params(nil)
        .and_return(nil)
    )
  end
end
