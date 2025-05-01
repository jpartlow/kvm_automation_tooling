#! /usr/bin/env ruby

require_relative "../lib/kvm_automation_tooling/command"

class DownloadImage < TaskHelper
  include KvmAutomationTooling::Command

  def task(image_url:, download_dir:, **kwargs)
    image_name = image_url.split('/').last
    image_path = File.expand_path("#{download_dir}/#{image_name}")
    results = {
      path: image_path,
      already_exists: true,
    }

    which!('curl', task_args: kwargs)

    if !File.exist?(image_path)
      cmd_array = ['curl', '--fail-with-body', '-L', '-o', image_path, image_url]
      output, status = Open3.capture2e(*cmd_array)
      if !status.success?
        http_response = nil
        begin
          if File.exist?(image_path)
            http_response = File.read(image_path)
            File.delete(image_path)
          end
        ensure
          err_msg = <<~ERR
            Failed to download '#{image_url}' to '#{image_path}'.
            Curl: #{cmd_array.join(' ')}
            Exit status: #{status.exitstatus}

            Output:
            #{output}

            Http response:
            #{http_response}
          ERR
          details = {
            command: cmd_array,
            output: output,
            http_response: http_response,
            status: status.exitstatus,
          }
          raise TaskHelper::Error.new(
            err_msg,
            "#{kwargs[:_task]}/cli",
            details
          )
        end
      end

      results[:curl] = cmd_array
      results[:output] = output
      results[:already_exists] = false
    end

    return results
  end
end

DownloadImage.run if __FILE__ == $0
