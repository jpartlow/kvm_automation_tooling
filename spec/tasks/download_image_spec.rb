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
      expect(Open3).to receive('capture2e').with('curl', '--fail-with-body', '-L', '-o', '/DIR/IMAGE', 'URL/IMAGE').and_return(['output', success])

      expect(task.task(image_url: 'URL/IMAGE', download_dir: '/DIR')).to match(
        {
          curl: ['curl', '--fail-with-body', '-L', '-o', '/DIR/IMAGE', 'URL/IMAGE'],
          output: 'output',
          path: '/DIR/IMAGE',
          already_exists: false,
        }
      )
    end

    it 'does nothing if image is present' do
      expect(File).to receive('exist?').with('/DIR/IMAGE').and_return(true)
      expect(task.task(image_url: 'URL/IMAGE', download_dir: '/DIR')).to match(
        {
          path: '/DIR/IMAGE',
          already_exists: true,
        }
      )
    end

    it 'expands download_dir to an absolute path' do
      expanded_dir = "#{ENV['HOME']}/DIR"
      expect(Open3).to receive('capture2e').with('curl', '--fail-with-body', '-L', '-o', "#{expanded_dir}/IMAGE", 'URL/IMAGE').and_return(['output', success])

      expect(task.task(image_url: 'URL/IMAGE', download_dir: '~/DIR')).to match(
        {
          curl: ['curl', '--fail-with-body', '-L', '-o', "#{expanded_dir}/IMAGE", 'URL/IMAGE'],
          output: 'output',
          path: "#{expanded_dir}/IMAGE",
          already_exists: false,
        }
      )
    end

    it 'raises an error if curl fails' do
      expect(Open3).to receive('capture2e').with('curl', '--fail-with-body', '-L', '-o', '/DIR/IMAGE', 'URL/IMAGE').and_return(['output', failure])
      expect do
        task.task(image_url: 'URL/IMAGE', download_dir: '/DIR')
      end.to(
        raise_error(TaskHelper::Error, %r{Failed to download 'URL/IMAGE' to '/DIR/IMAGE'})
      )
    end

    context 'with http response' do
      let(:tmpdir) { Dir.mktmpdir('kat-download_image_spec') }
      let(:output_path) { File.join(tmpdir, 'IMAGE') }

      around(:each) do |example|
        example.run
      ensure
        FileUtils.remove_entry_secure(tmpdir)
      end

      it 'raises an error if curl fails with http response' do
        expect(Open3).to(
          # --fail-with-body causes curl to exit non-zero for HTTP
          # 400+ responses, and save the response body to the file...
          receive('capture2e').with('curl', '--fail-with-body', '-L', '-o', output_path, 'URL/IMAGE') do
            File.write(output_path, 'HTTP 404 not found')
            ['output', failure]
          end
        )

        expect do
         task.task(image_url: 'URL/IMAGE', download_dir: tmpdir)
        end.to(
          raise_error(
            TaskHelper::Error,
            %r{Failed to download 'URL/IMAGE' to '#{output_path}'.+Http response:.+HTTP 404 not found}m
          )
        )
      end
    end
  end

  it 'raises an error if curl not found' do
    expect(Open3).to receive('capture3').with('which', 'curl').and_return(['', '', failure])
    expect { task.task(image_url: 'URL/IMAGE', download_dir: '/DIR') }.to raise_error(TaskHelper::Error, /Command 'curl' not found/)
  end
end

