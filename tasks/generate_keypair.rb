#! /usr/bin/env ruby

require 'tmpdir'
require_relative "../lib/kvm_automation_tooling/command"

class GenerateKeypair < TaskHelper
  include KvmAutomationTooling::Command

  def task(type:, bits: nil, **kwargs)
    tmpdir = Dir.mktmpdir('kat-generate-keypair')
    keyfile = "id_#{type}"
    pubkeyfile = "#{keyfile}.pub"

    cmd_array = ['ssh-keygen', '-t', type, '-f', "#{tmpdir}/#{keyfile}", '-N', '']
    cmd_array += ['-b', bits] if bits
    result = run!(cmd_array, task_args: kwargs)

    result.merge(
      tmpdir: tmpdir,
      keyfile: keyfile,
      pubkeyfile: pubkeyfile,
      pubkey: File.read("#{tmpdir}/#{pubkeyfile}"),
    )
  end
end

GenerateKeypair.run if __FILE__ == $0
