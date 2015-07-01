module RunCommand
  def run_command(command)
    # todo we need the output from the command e.g. for the branch in GitRepository
    # todo we should check if the command succeeds.
    # especially if we use mixlib's shellout which suppresses the output
    system(command)
  end
end
