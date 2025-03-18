#! /usr/bin/env ruby

require_relative "../lib/kvm_automation_tooling/command"

class DownloadImage < TaskHelper
  include KvmAutomationTooling::Command

  def task(image_url:, download_dir:, **kwargs)
    image_name = image_url.split('/').last
    image_path = "#{download_dir}/#{image_name}"
    status = {
      path: image_path,
      already_exists: true,
    }

    which!('curl', task_args: kwargs)

    if !File.exist?(image_path)
      cmd_array = ['curl', '-L', '-o', image_path, image_url]
      run!(cmd_array, task_args: kwargs, err_msg: "Failed to download '#{image_url}' to '#{download_dir}'.")
      status[:already_exists] = false
    end

    return status
  end
end

DownloadImage.run if __FILE__ == $0
