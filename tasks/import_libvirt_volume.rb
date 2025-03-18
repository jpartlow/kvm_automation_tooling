#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require_relative "../lib/kvm_automation_tooling/libvirt_wrapper.rb"

class ImportLibvirtVolume < TaskHelper
  include KvmAutomationTooling::LibvirtWrapper

  def task(image_path:, volume_name:, **kwargs)
    created = false
    with_libvirt do |lv|
      if !lv.volume_exist?(volume_name)
        lv.upload_volume(volume_name, file_path: image_path)
        created = true
      end
    end

    {
      status: 'success',
      created: created,
    }
  end
end

ImportLibvirtVolume.run if __FILE__ == $0
