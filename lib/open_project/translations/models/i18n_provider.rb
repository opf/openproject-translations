require 'yaml'
require 'crowdin-api'
require 'tempfile'
require 'zip'

class I18nProvider
  def initialize(project_id, api_key, crowdin_directory)
    @project_id = project_id
    @api_key = api_key
    @crowdin_directory = crowdin_directory
    @crowdin = create_handle
  end

  def create_handle
    Crowdin::API.new project_id: @project_id, api_key: @api_key
  end

  def upload_english(translation_file, path_to_translation, title)
    begin
      # create crowdin directory just in case it doesn't exist.
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
    unless crowdin_directory_exists?
      @crowdin.add_directory(@crowdin_directory)
    end
  end

  def crowdin_directory_exists?
    @crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
  end

  def file_exists_in_directory?(file)
    directory = @crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
    directory['files'].find {|f| f['name'] == file}
  end

  def update_file(dest:, source:, title:)
    @crowdin.update_file [{dest: dest,
                          source: source,
                          title: title,
                          export_pattern: '%two_letters_code%.yml'}],
                          type: 'yaml'
  end

  def add_file(dest:, source:, title:)
    @crowdin.add_file [{dest: dest,
                          source: source,
                          title: title,
                          export_pattern: '%two_letters_code%.yml'}],
                          type: 'yaml'
  end

  def request_build
    # todo maybe this could run into a timeout?
    begin
      @crowdin.export_translations
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_id}: #{e.message}"
    end
  end

  def download_locales(output)
    # todo what about errors? maybe a timeout?
    begin
      @crowdin.download_translation 'all', output: output
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_id}: #{e.message}"
    end
  end

  def each_locale
    begin
      languages_files = create_temp_file('crowdin_translations')
      download_locales(languages_files.path)
      Zip::File.open(languages_files.path) do |zip_file|
        zip_file.glob("*/#{@crowdin_directory}/*.yml").each do |entry|
          yield entry
        end
      end
    ensure
      unlink_temp_file(languages_files)
    end
  end

  def translation_status_high_enough?(code, percent)
    @translations_statuses ||= begin
      @crowdin.translations_status
    end
    translation_status = @translations_statuses.select do |translation|
      translation['code'] == code
    end
    if translation_status == []
      false
    else
      translation_status.first['translated_progress'].to_i >= percent
    end
  end

  def create_temp_file(filename)
    tempfile = Tempfile.new(filename)
    tempfile.close
    tempfile
  end

  def unlink_temp_file(tempfile)
    tempfile.unlink
  end
end
