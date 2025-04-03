require 'spec_helper'

describe 'kvm_automation_tooling::platform' do
  it 'returns a platform string' do
    is_expected.to(
      run.with_params({ 'os' => 'ubuntu', 'os_version' => '2204', 'os_arch' => 'amd64' })
        .and_return('ubuntu-2204-amd64')
    )
  end

  it 'removes delimeters from ubuntu version strings' do
    is_expected.to(
      run.with_params({ 'os' => 'ubuntu', 'os_version' => '22.04', 'os_arch' => 'amd64'})
        .and_return('ubuntu-2204-amd64')
    )
  end

  it 'switches to amd64 for ubuntu arch' do
    is_expected.to(
      run.with_params({ 'os' => 'ubuntu', 'os_version' => '2204', 'os_arch' => 'x86_64'})
        .and_return('ubuntu-2204-amd64')
    )
  end

  context 'with a Kvm_automation_tooling::Vm_spec' do
    let(:vm_spec) do
      {
        'role' => 'agent',
        'os' => 'ubuntu',
        'os_version' => '2204',
        'os_arch' => 'amd64',
        'cpus' => 2,
      }
    end

    it 'also works' do
      is_expected.to(run.with_params(vm_spec).and_return('ubuntu-2204-amd64'))
    end

    it 'raises an error if missing any of the os keys' do
      vm_spec.delete('os')
      is_expected.to(
        run.with_params(vm_spec)
        .and_raise_error(%r{An os,.*Received:})
      )
    end
  end
end
