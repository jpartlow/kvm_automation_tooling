require 'spec_helper'

describe 'kvm_automation_tooling::validate_vm_ip_addresses' do
  include BoltSpec::BoltContext

  let(:apply_result_json) do
    <<~JSON
      {
        "vm_ip_addresses": {
          "sensitive": false,
          "type": [
            "object",
            {
              "spec-agent-1": "string",
              "spec-agent-2": "string",
              "spec-primary-1": "string"
            }
          ],
          "value": {
            "spec-agent-1": "192.168.107.154",
            "spec-agent-2": "192.168.107.24",
            "spec-primary-1": "192.168.107.83"
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
      apply_result['vm_ip_addresses']['value'] = nil
      is_expected.to run.with_params(apply_result).and_return(false)
    end
  end

  context('valid result') do
    before(:each) do
      expect_out_message
    end

    it 'returns false for an empty value' do
      apply_result['vm_ip_addresses']['value'] = {}
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns false if an address is missing' do
      apply_result['vm_ip_addresses']['value']['spec-agent-1'] = nil
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns false if an address is not ipv4' do
      apply_result['vm_ip_addresses']['value']['spec-agent-2'] = "::1"
      is_expected.to run.with_params(apply_result).and_return(false)
    end

    it 'returns true if all addresses are ipv4' do
      is_expected.to run.with_params(apply_result).and_return(true)
    end
  end
end
