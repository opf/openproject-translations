require 'yaml'
require 'crowdin-api'

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
    # create crowdin directory just in case it doesn't exist.
    begin
      add_directory_if_missing

      if file_exists_in_directory?(translation_file)
        update_file(dest: "/#{@crowdin_directory}/#{translation_file}",
                    source: path_to_translation.to_s,
                    title: title)
      else
        add_file(dest: "/#{@crowdin_directory}/#{translation_file}",
                    source: path_to_translation.to_s,
                    title: title)
      end
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_de}: #{e.message}"
    end
  end

  def add_directory_if_missing
    crowdin = create_handle
    unless crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
      crowdin.add_directory(@crowdin_directory)
    end
  end

  def file_exists_in_directory?(file)
    crowdin = create_handle
    directory = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
    directory['files'].find {|f| f['name'] == file}
  end

  def update_file(dest:, source:, title:)
    crowdin = create_handle
    crowdin.update_file [{dest: dest,
                          source: source,
                          title: title,
                          export_pattern: '%two_letters_code%.yml'}],
                          type: 'yaml'
  end

  def add_file(dest:, source:, title:)
    crowdin = create_handle
    crowdin.add_file [{dest: dest,
                          source: source,
                          title: title,
                          export_pattern: '%two_letters_code%.yml'}],
                          type: 'yaml'
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

  def translation_status_high_enough?(code, percent)
    @translations_statuses ||= begin
      crowdin = create_crowdin_handle
      crowdin.translations_status
    end
    translation_status = @translations_statuses.select do |translation|
      translation['code'] == code
    end
    translation_status.first['translated_progress'].to_i >= percent
  end
end
