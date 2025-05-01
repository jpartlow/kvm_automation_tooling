require 'spec_helper'

describe 'kvm_automation_tooling::get_normalized_os_arch' do
  context 'debian' do
    it 'returns amd64 for x86_64' do
      is_expected.to(
        run.with_params('debian', 'x86_64')
          .and_return('amd64')
      )
      is_expected.to(
        run.with_params('ubuntu', 'x86_64')
          .and_return('amd64')
      )
    end

    it 'returns arm64 for aarch64' do
      pending
      is_expected.to(
        run.with_params('debian', 'aarch64')
          .and_return('arm64')
      )
      is_expected.to(
        run.with_params('ubuntu', 'aarch64')
          .and_return('arm64')
      )
    end
  end

  context 'other' do
    it 'returns x86_64 for amd64' do
      pending
      is_expected.to(
        run.with_params('rocky', 'amd64')
          .and_return('x86_64')
      )
    end

    it 'returns aarch64 for arm64' do
      pending
      is_expected.to(
        run.with_params('rocky', 'arm64')
          .and_return('aarch64')
      )
    end
  end
end
