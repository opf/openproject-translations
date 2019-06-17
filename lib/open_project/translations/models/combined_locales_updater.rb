require 'pathname'
require 'fileutils'
require 'crowdin-api'

class CombinedLocalesUpdater
  attr_reader :crowdin,
              :project,
              :crowdin_version_dir,
              :debug

  ENGLISH_TRANSLATION_FILE ||= 'en.yml'
  ENGLISH_JS_TRANSLATION_FILE ||= 'js-en.yml'
  ACCEPTANCE_LEVEL ||= ENV['ACCEPTANCE_LEVEL'].nil? ? 75 : ENV['ACCEPTANCE_LEVEL'].to_i

  ##
  # Create a combined locales updater.
  #
  # @param core_path OpenProject checked out core
  # @param project crowdin project identifier
  # @param api_key crowdin API key for the project
  def initialize(project, api_key)
    @project = project
    @crowdin = ::Crowdin::API.new project_id: project, api_key: api_key
    @crowdin_version_dir = "#{OpenProject::VERSION::MAJOR}.#{OpenProject::VERSION::MINOR}"
    @debug = false
  end

  def call!
    Dir.chdir(Rails.root) do
      puts "-- Uploading all translations --"
      all_locale_paths.each { |dir| upload_translations(dir) }

      puts "-- Requesting build --"
      request_build

      puts "-- Waiting for build to be completed --"
      wait_for_build_completion

      puts "-- Downloading and updating all translations --"
      download_locales do |zip_file|
        all_locale_paths.each do |module_dir|
          mod_name = get_crowdin_name(module_dir)
          path = versioned_path(mod_name)
          entries =  zip_file.glob("*/#{path}/*.yml")
          Dir.chdir(module_dir) { replace_locales(module_dir, entries) }
        end
      end
    end
  end

  private

  ##
  # Download the latest translations build from crowdin
  def download_locales
    Tempfile.create 'crowdin_translations' do |file|
      crowdin.download_translation 'all', output: file.path
      Zip::File.open(file.path) do |zip_file|
        yield zip_file
      end
    end
  end

  ##
  # Override local crowdin locales
  def replace_locales(mod_path, entries)
    mod_name = get_crowdin_name(mod_path)

    target_directory = Pathname(File.join('crowdin'))
    unless File.directory?(target_directory)
      FileUtils.mkdir_p(target_directory)
    end

    # Clear all locales before checking in the current ones
    FileUtils.rm_f Dir.glob("#{target_directory}/*.yml")

    entries.each do |entry|
      language_name = entry.name.split('/').first # the file is put in a directory containing the language name

      # only take translations with enough percent translated
      next unless translation_status_high_enough?(language_name, ACCEPTANCE_LEVEL)

      filepath = target_directory.join "#{js_translation?(Pathname.new(entry.name)) ? 'js-' : ''}#{language_name}.yml"
      replace_file(filepath, entry)
    end
  end

  ##
  # Replace a single translation file from crowdin
  def replace_file(filepath, new_file)
    File.delete(filepath) if File.file?(filepath)

    contents = new_file.get_input_stream.read

    # work around a crowdin bug which does not escape norwegian key
    # and results in boolean
    language_key = calculate_language_key filepath
    if language_key == 'no'
      contents.gsub! /\Ano:/, '"no":'
    end

    File.open(filepath, 'wb') do |file|
      file.write contents
    end
  end

  ##
  # Determine and fix the localization language key from the file path
  def calculate_language_key(translation_file_path)
    # The main translation key is the language key ('en' for english, 'zh' for chinese etc.)
    # Sometimes a language has multiple variants (eg simplified chinese 'zh-TW')
    # For language variants ('zh-TW') crowdin gives us only the language key ('zh') so we replace it.
    # from /path/to/openproject-translations/config/locales/zh-TW.yml we extract 'zh-TW'
    language_key = if js_translation?(translation_file_path)
      # ignore the 'js-' prefix of js translations
      translation_file_path.basename.to_s[3..-5]
    else
      translation_file_path.basename.to_s[0..-5]
    end

    # Unfortunately OpenProject has some vendored translations in jstoolbar, which
    # needs different names sometimes, so we map exceptions here
    mapping = Hash.new {|hash, key| key }
    mapping['zh-CN'] = 'zh'
    mapping['es-ES'] = 'es'
    mapping['pt-PT'] = 'pt'

    mapping[language_key]
  end

  ##
  # Upload the given locale path to crowdin.
  # Checks for en.yml and js-en.yml presence.
  def upload_translations(path)
    mod_name = get_crowdin_name(path)

    unless File.exists?("#{path}/en.yml") || File.exists?("#{path}/js-en.yml")
      puts "-> Skipping #{mod_name} because *en.yml not present"
      return
    end

    puts "-> Creating directory #{mod_name}"
    create_crowdin_directory(mod_name)

    puts "-> Uploading en.yml and js-en.yml"
    upload_english mod_name,
                   path,
                   ENGLISH_TRANSLATION_FILE,
                   "Module #{mod_name.capitalize}",
                   '%two_letters_code%.yml'

    upload_english mod_name,
                   path,
                   ENGLISH_JS_TRANSLATION_FILE,
                   "Module #{mod_name.capitalize} Frontend",
                   'js-%two_letters_code%.yml'
  end

  ##
  # Perform the upload of a single yml file
  def upload_english(mod_name, mod_path, filename, title, export_pattern)
    crowdin_path = versioned_path(mod_name, filename)
    path_to_translation = File.join(mod_path, filename)
    return unless File.exists?(path_to_translation)

    begin
      if crowdin_file_exists?(crowdin_path)
        debug_print "Updating file #{crowdin_path}"
        crowdin.update_file([
          dest: crowdin_path,
          source: path_to_translation.to_s,
          title: title,
          type: 'yaml',
          export_pattern: export_pattern
        ])
      else
        debug_print "Uploading new file #{crowdin_path}"
        crowdin.add_file([
          dest: crowdin_path,
          source: path_to_translation.to_s,
          title: title,
          type: 'yaml',
          export_pattern: export_pattern
        ])
      end
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{crowdin_path}: #{e.message}"
      raise e
    end
  end

  ##
  # Return whether the given language is ranked high
  # enough in the crowdin project.
  def translation_status_high_enough?(code, percent)
    @translations_statuses ||= begin
      crowdin.translations_status
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

  ##
  # Request a new full build of the project
  def request_build
    begin
      debug_print "Exporting translations"
      resp = crowdin.export_translations async: 1
      debug_print resp.inspect
    rescue Crowdin::API::Errors::Error => e
      puts "Error during update of #{@project_id}: #{e.message}"
      raise e
    end
  end

  ##
  # The crowdin build may take quite a number of time and exceed any http timeout
  # thus we request the translations asynchronously and simply wait for completion
  # by requesting the export-status call until status is not in-progress.
  def wait_for_build_completion
    while true do
      response = crowdin.request method: :get,
                                path: "/api/project/#{project}/export-status"
      status = response['status']
      progress = response['progress']

      puts "Export status: #{status} (Progress #{progress || 'not known'})"
      break if status != 'in-progress'

      puts "Waiting for completion, sleeping a bit..."
      sleep 10
    end

  rescue StandardError => e
    warn "Failed to wait for completion: #{e} #{e.message}"
  end

  ##
  # Create the given directory unless exists on crowdin
  def create_crowdin_directory(module_name)
    path = versioned_path(module_name)
    return if find_entry(path)

    debug_print "Creating directory #{path}"
    crowdin.add_directory(path)
  rescue ::Crowdin::API::Errors::Error => e
    raise e unless e.message == 'Directory with such name already exists'
  end

  ##
  # Check whether crowdin has the given file
  def crowdin_file_exists?(path)
    entry = find_entry(path)
    entry && entry['node_type'] == 'file'
  rescue StandardError => e
    warn "Could not identify whether #{path} exists: #{e} #{e.message}"
    false
  end

  ##
  # Prefix the path for crowdin using the current core version
  # crowdin will receive the path of /X.Y/module/en.yml
  def versioned_path(*path)
    File.join(crowdin_version_dir, *path)
  end

  def debug_print(msg)
    return unless debug
    puts "[DEBUG] #{msg}"
  end

  ##
  # Look up the nested path info from crowdin
  def find_entry(path)
    entry = crowdin.project_info

    path
      .split('/')
      .each do |segment|

      entry = entry['files'].find { |f| f['name'] == segment }
      return nil if entry.nil?
    end

    entry
  end

  ##
  # Get the folder name we track this module in
  def get_crowdin_name(path)
    if match = path.match(/modules\/([^\/]+)\/config\/locales/)
      match[1]
    else
      'core'
    end
  end

  ##
  # Extracts all available modules for uploading
  def all_locale_paths
    ['config/locales'] + Dir.glob('modules/*/config/locales')
  end

  def js_translation?(translation_file_path)
    !!(translation_file_path.basename.to_s[0..-5] =~ /\Ajs-.+\z/)
  end
end
