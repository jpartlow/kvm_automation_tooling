require 'spec_helper'

describe 'kvm_automation_tooling::validate_openvox_version_parameters' do
  include BoltSpec::BoltContext

  let(:params) do
    {
      'openvox_version'    => '8.0.0',
      'openvox_collection' => 'openvox8',
      'openvox_released'   => true,
    }
  end

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  it 'returns given valid parameters' do
    is_expected.to(
      run.with_params(params).and_return(params)
    )
  end

  context 'for released versions' do
    it 'replaces collection if it does not match version' do
      params['openvox_version'] = '7.0.0'
      expect(params['openvox_collection']).to eq('openvox8')
      is_expected.to(
        run.with_params(params)
          .and_return(params.merge('openvox_collection' => 'openvox7'))
      )
    end

    it 'allows a version of "latest"' do
      params['openvox_version'] = 'latest'
      is_expected.to(
        run.with_params(params).and_return(params)
      )
    end

    it 'raises an error if version does not have a valid collection' do
      params['openvox_version'] = '5.0.0'
      is_expected.to(
        run.with_params(params)
          .and_raise_error(/'5\.0\.0' suggests a collection 'openvox5' that does not exist/)
      )
    end
  end

  context 'for pre-release versions' do
    before(:each) do
      params['openvox_released'] = false
    end

    it 'returns given valid parameters' do
      is_expected.to(
        run.with_params(params).and_return(params)
      )
    end

    it 'raises an error if given version latest' do
      params['openvox_version'] = 'latest'
      is_expected.to(
        run.with_params(params)
          .and_raise_error(/must supply an explicit version/)
      )
    end
  end

  context 'when parameters are missing' do
    let(:default) do
      {
        'openvox_released'   => true,
        'openvox_version'    => 'latest',
        'openvox_collection' => 'openvox8',
      }
    end

    it 'returns defaults if given nothing' do
      is_expected.to(
        run.with_params({}).and_return(default)
      )
    end

    it 'adds defaults if given partial parameters' do
      is_expected.to(
        run.with_params('openvox_version' => '7.0.0')
          .and_return(
            default.merge(
              'openvox_version' => '7.0.0',
              'openvox_collection' => 'openvox7'
            )
          )
      )
      is_expected.to(
        run.with_params('openvox_collection' => 'openvox7')
          .and_return(
            default.merge(
              'openvox_collection' => 'openvox7'
            )
          )
      )
    end

    it 'raises if given just openvox_released false' do
      is_expected.to(
        run.with_params('openvox_released' => false)
          .and_raise_error(/must supply an explicit version/)
      )
    end

    it 'does not touch artifacts_url' do
      artifacts = 'https://spec/artifacts'
      p = { 'openvox_artifacts_url' => artifacts }
      is_expected.to(
        run.with_params(p).and_return(
          default.merge(p)
        )
      )
    end
  end
end
