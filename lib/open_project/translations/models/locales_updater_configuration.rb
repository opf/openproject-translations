require 'yaml'

class LocalesUpdaterConfiguration
  CONFIGURATION_FILE = ENV['CONFIGURATION_FILE'] || begin
    # root of OpenProject-Translation
    configuration_file = Pathname(__FILE__) + '../../../../../'
    configuration_file + 'configuration.yml'
  end

  def self.configuration
    # TODO: raise error if something is missing
    @configuration ||= YAML.load_file(CONFIGURATION_FILE)
  end
end
