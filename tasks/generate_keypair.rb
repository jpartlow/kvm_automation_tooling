#! /usr/bin/env ruby

require_relative "../lib/kvm_automation_tooling/command"

class GenerateKeypair < TaskHelper
  include KvmAutomationTooling::Command

  def task(type:, bits: nil, **kwargs)
    tempdir = Dir.mktmpdir
    keyfile = "id_#{type}"
    pubkeyfile = "#{keyfile}.pub"

    cmd_array = ['ssh-keygen', '-t', type, '-f', "#{tempdir}/#{keyfile}", '-N', '']
    cmd_array += ['-b', bits] if bits
    result = run!(cmd_array, task_args: kwargs)

    result.merge(
      tmpdir: tempdir,
      keyfile: keyfile,
      pubkeyfile: pubkeyfile,
    )
  end
end

GenerateKeypair.run if __FILE__ == $0
