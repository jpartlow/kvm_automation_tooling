require 'open3'

require_relative '../../../ruby_task_helper/files/task_helper'

module KvmAutomationTooling

  # Provides an interface for common command execution tasks using the Open3 library.
  module Command

    # Runs the given command array through Open3 and returns a hash with the results, capturing both stderr and stdout.
    #
    # See run! for more details.
    def run3!(cmd_array, task_args:, err_msg: nil)
      run!(cmd_array, task_args: task_args, err_msg: err_msg, err_stream: true)
    end

    # Runs the given command array through Open3 and returns a hash with the results.
    #
    # @param cmd_array [Array<String>] The command to run.
    # @param task_args [Hash{Symbol => Object}] The task arguments.
    # @param err_msg [String] An optional error message to display if the command fails.
    # @param err_stream [Boolean] Whether to capture stderr as a separate stream.
    # @return [Hash{Symbol => Object}] A hash with the keys :command, :output, :status, and optionally :stderr.
    # @raise [TaskHelper::Error] If the command fails.
    def run!(cmd_array, task_args:, err_msg: nil, err_stream: false)
      if err_stream
        output, stderr, status = Open3.capture3(*cmd_array)
      else
        output, status = Open3.capture2e(*cmd_array)
      end

      details = {
        command: cmd_array,
        output: output,
        status: status.exitstatus,
      }
      details[:stderr] = stderr if err_stream

      if !status.success?
        task = task_args[:_task]
        err_header = err_msg.nil? ? 'Execution failed.' : err_msg

        msg = <<~MSG
          #{err_header}
          Command: #{cmd_array.join(' ')}
          Exit status: #{status.exitstatus}
          Output:
          #{output}
        MSG
        msg += "Error output:\n#{stderr}" if err_stream

        raise TaskHelper::Error.new(
          msg,
          "#{task}/cli",
          details
        )
      end

      details
    end

    # Executes the given command and returns true if it succeeds, false otherwise.
    # @param cmd_array [Array<String>] The command to run.
    # @return [Boolean] True if the command succeeds, false otherwise.
    def test(cmd_array)
      _, status = Open3.capture2e(*cmd_array)
      status.success?
    end

    # Executes the given command and returns the stripped output.
    # @param cmd_array [Array<String>] The command to run.
    # @return [String] The stripped output of the command.
    def capture(cmd_array, task_args:, err_msg: 'Failed to capture output.')
      run3!(cmd_array, task_args: task_args, err_msg: err_msg)[:output].strip
    end

    # Checks if the given command is available in the system's PATH.
    # @param command [String] The command to check.
    # @return [String, nil] The path to the command if it exists, nil otherwise.
    def which(command)
      which!(command)
    rescue TaskHelper::Error
      return nil
    end

    # Checks if the given command is available in the system's PATH.
    # @param command [String] The command to check.
    # @return [String] The path to the command.
    # @raise [TaskHelper::Error] If the command does not exist.
    def which!(command, task_args: {})
      capture(['which', command], task_args: task_args, err_msg: "Command '#{command}' not found in path #{ENV['PATH']}.")
    end
  end
end
