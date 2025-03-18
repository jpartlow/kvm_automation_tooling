require 'spec_helper'

require 'kvm_automation_tooling/command'

describe KvmAutomationTooling::Command do
  class TestTask
    include KvmAutomationTooling::Command
  end

  let(:task) { TestTask.new }

  describe '#run!' do
    it 'runs a command' do
      expect(task.run!(['echo', 'hi'], task_args: {})).to(
        eq(
          {
            command: ['echo', 'hi'],
            output: "hi\n",
            status: 0,
          }
        )
      )
    end

    it 'raises an error when a command fails' do
      expect {
        task.run!(['ls', '--bad-option'], task_args: { _task: 'bad-task' }, err_msg: 'oops')
      }.to raise_error(TaskHelper::Error, /oops/) do |e|
        expect(e.kind).to eq('bad-task/cli')
        expect(e.details[:command]).to eq(['ls', '--bad-option'])
        expect(e.details[:status]).to eq(2)
        expect(e.details[:output]).to match(/ls: unrecognized option '--bad-option'/)
      end
    end
  end

  describe '#run3!' do
    it 'runs a command capturing separate stdout and stderr streams' do
      expect(task.run3!([%q{echo 'stdout' && echo 'stderr' >&2}], task_args: {})).to(
        eq(
          {
            command: ["echo 'stdout' && echo 'stderr' >&2"],
            output: "stdout\n",
            stderr: "stderr\n",
            status: 0,
          }
        )
      )
    end

    it 'raises an error with stderr output when a command fails' do
      expect {
        task.run3!(['ls', '--bad-option'], task_args: { _task: 'bad-task' }, err_msg: 'oops')
      }.to raise_error(TaskHelper::Error, /oops/) do |e|
        expect(e.kind).to eq('bad-task/cli')
        expect(e.details[:command]).to eq(['ls', '--bad-option'])
        expect(e.details[:status]).to eq(2)
        expect(e.details[:stderr]).to match(/ls: unrecognized option '--bad-option'/)
        expect(e.details[:output]).to be_empty
      end
    end
  end

  describe '#which' do
    it 'returns the path to an executable' do
      expect(task.which('echo')).to match(%r{.+/echo})
    end

    it 'returns nil when not present' do
      expect(task.which('nonexistent-command')).to be_nil
    end
  end

  describe '#which!' do
    it 'returns the path to an executable' do
      expect(task.which!('echo')).to match(%r{.+/echo})
    end

    it 'raises an error when it does not exist' do
      expect {
        task.which!('nonexistent-command')
      }.to raise_error(TaskHelper::Error, /Command 'nonexistent-command' not found/)
    end
  end
end
