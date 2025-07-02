require 'spec_helper'

describe 'plan: kvm_automation_tooling::subplans::install_server_prerequisites' do
  include_context 'plan_init'

  let(:install_params) { {} }
  let(:defaults) do
    {
      'openvox_released' => true,
    }
  end
  let(:plan_params) do
    {
      'targets'  => 'spec',
      'package'  => 'openvox-server',
      'params'   => install_params,
      'defaults' => defaults,
    }
  end

  it 'applies if package matches and not released' do
    install_params['openvox_released'] = false
    install_params['openvox_version'] = '8.0.0'

    allow_apply
    expect_out_message

    $result = run_plan(
      'kvm_automation_tooling::subplans::install_server_prerequisites',
      plan_params
    )
    expect($result.ok?).to(eq(true), $result.value.to_s)
  end

  it 'does not apply if package does not match' do
    plan_params['package'] = 'openvox-agent'
    install_params['openvox_released'] = false
    install_params['openvox_version'] = '8.0.0'

    $result = run_plan(
      'kvm_automation_tooling::subplans::install_server_prerequisites',
      plan_params
    )
    expect($result.ok?).to(eq(true), $result.value.to_s)
  end

  it 'does not apply if released' do
    $result = run_plan(
      'kvm_automation_tooling::subplans::install_server_prerequisites',
      plan_params
    )
    expect($result.ok?).to(eq(true), $result.value.to_s)
  end

  it 'fails if parameters do not validate' do
    install_params['openvox_released'] = false

    $result = run_plan(
      'kvm_automation_tooling::subplans::install_server_prerequisites',
      plan_params
    )
    expect($result.ok?).to(eq(false))
    expect($result.value.to_s).to match(/must supply an explicit version/)
  end
end
