#! /usr/bin/env ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require 'ipaddr'
require 'json'

class ResolveReference < TaskHelper
  def load_statefile(dir:, statefile:)
    path = File.join(dir, statefile)
    File.exist?(path) ?
      JSON.parse(File.read(path)) :
      {}
  rescue StandardError => e
    msg = "Failed to load tfstate file from #{path}:\n#{e}"
    raise TaskHelper::Error.new(msg, 'kvm_automation_tooling/resolve_reference-error')
  end

  def resolve_targets(**kwargs)
    role = kwargs[:role]
    tfstate = load_statefile(dir: kwargs[:dir], statefile: kwargs[:statefile])
    vmdomain_details = tfstate.dig('outputs', 'vmdomain_details', 'value') || {}

    vmdomain_details.filter_map do |hostname,vm_info|
      ip_addresses = Array(vm_info['ip_addresses'])
      if vm_info['role'] == role
        first_ip = ip_addresses.find do |ip|
          IPAddr.new(ip).ipv4?
        rescue IPAddr::Error
          false
        end || ip_addresses.first

        {
          'name' => hostname,
          'uri'  => first_ip,
          'vars' => {
            'platform' => vm_info['platform'],
          },
        }
      end
    end
  end

  def task(**kwargs)
    targets = resolve_targets(**kwargs)
    { value: targets }
  end
end

ResolveReference.run if __FILE__ == $0
