#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require_relative "../lib/kvm_automation_tooling/libvirt_wrapper.rb"

class CreateLibvirtImagePool < TaskHelper
  include KvmAutomationTooling::LibvirtWrapper

  def task(name:, path: name, **kwargs)
    created = false
    with_libvirt do |lv|
      if !lv.pool_exist?(name)
        target_path = File.absolute_path?(path) ?
          path :
          "#{KvmAutomationTooling::LibvirtWrapper::DEFAULT_POOL_PATH}/#{path}"
        lv.create_pool(name, target_path)
        created = true
      end
    end

    {
      status: 'success',
      created: created,
    }
  end
end

CreateLibvirtImagePool.run if __FILE__ == $0
