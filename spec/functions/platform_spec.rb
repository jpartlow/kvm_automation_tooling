require 'spec_helper'

describe 'kvm_automation_tooling::platform' do
  context 'ubuntu' do
    it 'returns a platform string' do
      is_expected.to(
        run.with_params({ 'name' => 'ubuntu', 'version' => '2204', 'arch' => 'amd64' })
          .and_return('ubuntu-2204-amd64')
      )
    end

    it 'removes delimeters from ubuntu version strings' do
      is_expected.to(
        run.with_params({ 'name' => 'ubuntu', 'version' => '22.04', 'arch' => 'amd64'})
          .and_return('ubuntu-2204-amd64')
      )
    end

    it 'switches to amd64 for ubuntu arch' do
      is_expected.to(
        run.with_params({ 'name' => 'ubuntu', 'version' => '2204', 'arch' => 'x86_64'})
          .and_return('ubuntu-2204-amd64')
      )
    end
  end

  context 'debian' do
    it 'returns a platform string' do
      is_expected.to(
        run.with_params({ 'name' => 'debian', 'version' => '12', 'arch' => 'amd64' })
          .and_return('debian-12-amd64')
      )
    end

    it 'switches to amd64 for debian arch' do
      is_expected.to(
        run.with_params({ 'name' => 'debian', 'version' => '12', 'arch' => 'x86_64'})
          .and_return('debian-12-amd64')
      )
    end
  end

  context 'rocky' do
    it 'returns a platform string' do
      is_expected.to(
        run.with_params({ 'name' => 'rocky', 'version' => '9', 'arch' => 'x86_64' })
          .and_return('rocky-9-x86_64')
      )
    end

    it 'switches to x86_64 for rocky arch' do
      is_expected.to(
        run.with_params({ 'name' => 'rocky', 'version' => '9', 'arch' => 'amd64'})
          .and_return('rocky-9-x86_64')
      )
    end
  end
end
