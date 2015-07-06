require 'yaml'

class LocalesUpdaterConfiguration
  REQUIRED_KEYS = [:uri, :api_key, :project_id, :version,
  :version, :branch]

  def self.path_to_configuration_file
    ENV['CONFIGURATION_FILE'] || begin
      # root of OpenProject-Translation
      configuration_file = Pathname(__FILE__) + '../../../../../'
      configuration_file + 'configuration.yml'
    end
  end

  def self.configuration
    @configuration ||= YAML.load_file(path_to_configuration_file)
    check_for_structure
    check_for_required_keys
    @configuration
  end

  def self.check_for_structure
    unless @configuration.has_key?(:plugins)
      raise "Configuration file doesn't have :plugins key"
    end
    if @configuration[:plugins].nil?
      raise "Configuration file has empty :plugins key"
    end
  end

  def self.check_for_required_keys
    @configuration[:plugins].each do |plugin_name, specifics|
      REQUIRED_KEYS.each do |key|
        if @configuration[:plugins][plugin_name].nil?
          raise "Configuration file has empty configuration for plugin #{plugin_name}"
        end
        unless @configuration[:plugins][plugin_name].has_key?(key)
          raise "Configuration file doesn't have key '#{key}' for plugin #{plugin_name}."
        end
        if @configuration[:plugins][plugin_name][key].nil?
          raise "Configuration file has empty key '#{key}' for plugin #{plugin_name}"
        end
      end
    end
  end
end
