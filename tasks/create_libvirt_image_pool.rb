#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require_relative "../lib/kvm_automation_tooling/libvirt_wrapper.rb"

class CreateLibvirtImagePool < TaskHelper
  include KvmAutomationTooling::LibvirtWrapper

  def task(name:, **kwargs)
    created = false
    with_libvirt do |lv|
      if !lv.pool_exist?(name)
        lv.create_pool(name)
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
