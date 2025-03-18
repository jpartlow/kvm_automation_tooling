require 'spec_helper'

require_relative '../../tasks/create_libvirt_image_pool'

describe 'task: create_libvirt_image_pool' do
  let(:task) { CreateLibvirtImagePool.new }
  let(:existing_pool_name) { 'spec-test-pool-that-exists' }
  let(:client) do
    double('KvmAutomationTooling::LibvirtWrapper::Client')
  end

  before(:each) do
    expect(task).to receive(:with_libvirt).and_yield(client)
  end

  it 'creates a pool' do
    expect(client).to receive(:pool_exist?).with('a-new-pool').and_return(false)
    expect(client).to receive(:create_pool).with('a-new-pool')

    expect(task.task(name: 'a-new-pool')).to include(created: true)
  end

  it 'does not create a pool if it already exists' do
    expect(client).to receive(:pool_exist?).with(existing_pool_name).and_return(true)

    expect(task.task(name: existing_pool_name)).to include(created: false)
  end
end
