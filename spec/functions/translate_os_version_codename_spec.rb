require 'spec_helper'

describe 'kvm_automation_tooling::translate_os_version_codename' do
  context 'version to codename' do
    it 'returns an ubuntu codename' do
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

    it 'raises an error for unknown ubuntu version' do
      is_expected.to(
        run.with_params('ubuntu', '9999')
          .and_raise_error(/does not know the ubuntu translation for/)
      )
    end

    it 'returns a debian codename' do
      is_expected.to(
        run.with_params('debian', '10')
          .and_return('buster')
      )
    end

    it 'handles a debian major.minor version' do
      is_expected.to(
        run.with_params('debian', '10.1')
          .and_return('buster')
      )
    end

    it 'raises an error for an unknown debian version' do
      is_expected.to(
        run.with_params('debian', '9999')
          .and_raise_error(/does not know the debian translation for/)
      )
    end
  end

  context 'codename to version' do
    it 'returns an ubuntu version' do
      is_expected.to(
        run.with_params('ubuntu', 'noble')
          .and_return('2404')
      )
    end

    it 'raises an error for unknown ubuntu codename' do
      is_expected.to(
        run.with_params('ubuntu', 'thisisnotacodenameihope')
          .and_raise_error(/does not know the ubuntu translation for/)
      )
    end

    it 'returns a debian version' do
      is_expected.to(
        run.with_params('debian', 'trixie')
          .and_return('13')
      )
    end

    it 'raises an error for an unknown debian version' do
      is_expected.to(
        run.with_params('debian', 'alsoprobablynotacodename')
          .and_raise_error(/does not know the debian translation for/)
      )
    end
  end

  it 'returns what it was given for a non debian based os' do
    is_expected.to(
      run.with_params('rocky', '9').and_return('9')
    )
  end
end
