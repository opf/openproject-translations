require 'yaml'

require_relative './locales_updater_configuration.rb'

class I18nProvider
  def initialize(project_id, api_key, crowdin_directory)
    @project_id = project_id
    @api_key = api_key
    @crowdin_directory = crowdin_directory
  end

  def create_handle
    Crowdin::API.new project_id: @project_id, api_key: @api_key
  end

  def configuration
    LocalesUpdaterConfiguration.configuration
  end

  def upload_english(translation_file, path_to_translation, title)
    crowdin = create_handle

    # create crowdin directory just in case it doesn't exist.
    begin
      dir = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
      unless dir
        crowdin.add_directory(@crowdin_directory)
      end

      dir = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}

      if dir['files'].find {|f| f['name'] == translation_file}
        crowdin.update_file [{dest: "/#{@crowdin_directory}/#{translation_file}",
                              source: path_to_translation.to_s,
                              title: title,
                              export_pattern: '%two_letters_code%.yml'}],
                              type: 'yaml'
      else
        crowdin.add_file [{dest: "/#{@crowdin_directory}/#{translation_file}",
                           source: path_to_translation.to_s,
                           title: title,
                           export_pattern: '%two_letters_code%.yml'}],
                           type: 'yaml'
      end
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_de}: #{e.message}"
    end
  end

  def request_build
    # todo maybe this could run into a timeout?
    begin
      crowdin = create_handle
      crowdin.export_translations
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_id}: #{e.message}"
    end
  end

  def download_locales(output)
    # todo what about errors? maybe a timeout?
    begin
      crowdin = create_handle
      crowdin.download_translation 'all', output: output
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_id}: #{e.message}"
    end
  end
end
