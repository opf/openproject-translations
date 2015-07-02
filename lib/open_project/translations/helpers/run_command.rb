require 'mixlib/shellout'

module RunCommand
  def run_command(command)
    shell = Mixlib::ShellOut.new(command)
    shell.run_command
    raise "The following command returned an error: #{command}" if shell.error? &&
      !shell.stdout =~ /nothing to commit/

    shell.stdout.gsub(/\n$/, '')
  end
end
