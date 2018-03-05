require 'yaml'

class LocalesUpdaterConfiguration
  def self.configuration
    @configuration ||= begin
      path = ENV.fetch 'OPENPROJECT_TRANSLATIONS_CONFIGURATION_FILE'
      YAML.load_file(path).with_indifferent_access
    end
  end
end
