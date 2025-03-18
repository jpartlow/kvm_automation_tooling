require 'spec_helper'

require_relative '../../tasks/download_image'

describe 'task: download_image.rb' do
  let(:task) { DownloadImage.new }
  let(:success) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failure) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  describe 'with curl' do
    before(:each) do
      expect(Open3).to receive('capture3').with('which', 'curl').and_return(['/usr/bin/curl', '', success])
    end

    it 'downloads the image if not present' do
      expect(Open3).to receive('capture2e').with('curl', '-L', '-o', 'DIR/IMAGE', 'URL/IMAGE').and_return(['output', success])
  
      expect(task.task(image_url: 'URL/IMAGE', download_dir: 'DIR')).to match(
        {
          path: 'DIR/IMAGE',
          already_exists: false,
        }
      )
    end

    it 'does nothing if image is present' do
      expect(File).to receive('exist?').with('DIR/IMAGE').and_return(true)
      expect(task.task(image_url: 'URL/IMAGE', download_dir: 'DIR')).to match(
        {
          path: 'DIR/IMAGE',
          already_exists: true,
        }
      )
    end

    # ~/images doesn't get expanded within an Open3 call...
    it 'expands download_dir to an absolute path'
  end

  it 'raises an error if curl not found' do
    expect(Open3).to receive('capture3').with('which', 'curl').and_return(['', '', failure])
    expect { task.task(image_url: 'URL/IMAGE', download_dir: 'DIR') }.to raise_error(TaskHelper::Error, /Command 'curl' not found/)
  end
end

