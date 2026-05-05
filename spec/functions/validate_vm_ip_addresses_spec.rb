require 'spec_helper'

describe 'kvm_automation_tooling::validate_vm_ip_addresses' do
  include BoltSpec::BoltContext

  let(:apply_result_json) do
    <<~JSON
      {
        "vmdomain_details": {
          "sensitive": false,
          "type": null,
          "value": {
            "spec-agent-1": {
              "ip_addresses": ["192.168.106.79"],
              "platform": "ubuntu-2404-amd64",
              "role": "agent"
            },
            "spec-agent-2": {
              "ip_addresses": ["192.168.106.89"],
              "platform": "ubuntu-2404-amd64",
              "role": "agent"
            }
          }
        }
      }
    JSON
  end
  let(:apply_result) do
    JSON.parse(apply_result_json)
  end

  around(:each) do |example|
    in_bolt_context do
      example.run
    end
  end

  context('invalid result') do
    it 'returns false for an empty result' do
      is_expected.to run.with_params({}).and_return(false)
    end

    it 'returns false if an undef value' do
      apply_result
      apply_result['vmdomain_details']['value'] = nil
      is_expected.to run.with_params(apply_result).and_return(false)
    end
  end

  context('valid result') do
    before(:each) do
      expect_out_message
    end

    it 'returns false for an empty value' do
      apply_result['vmdomain_details']['value'] = {}
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns false if an address is missing' do
      apply_result['vmdomain_details']['value']['spec-agent-1']['ip_addresses'] = nil
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns false if an address is not ipv4' do
      apply_result['vmdomain_details']['value']['spec-agent-2']['ip_addresses'] = ['::1']
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns true if all addresses are ipv4' do
      is_expected.to run.with_params(apply_result).and_return(true)
    end

    it 'returns true if every vm has at least one ipv4 address' do
      apply_result['vmdomain_details']['value']['spec-agent-1']['ip_addresses'] = ['::1', '192.168.30.2']
      is_expected.to run.with_params(apply_result).and_return(true)
    end
  end
end
