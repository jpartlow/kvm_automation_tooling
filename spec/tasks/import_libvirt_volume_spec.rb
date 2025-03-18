require 'spec_helper'

require_relative '../../tasks/import_libvirt_volume'

describe 'task: import_libvirt_volume' do
  let(:task) { ImportLibvirtVolume.new }
  let(:client) do
    double('KvmAutomationTooling::LibvirtWrapper::Client')
  end

  before(:each) do
    expect(task).to receive(:with_libvirt).and_yield(client)
  end

  it 'uploads a volume' do
    expect(client).to receive(:volume_exist?).with('test_volume_name').and_return(false)
    expect(client).to receive(:upload_volume).with('test_volume_name', file_path: '/spec/testimage.img').and_return(true)

    expect(task.task(image_path: '/spec/testimage.img', volume_name: 'test_volume_name')).to include(created: true)
  end

  it 'does not upload a volume if it already exists' do
    expect(client).to receive(:volume_exist?).with('volume_that_exists').and_return(true)

    expect(task.task(image_path: '/spec/testimage.img', volume_name: 'volume_that_exists')).to include(created: false)
  end
end
