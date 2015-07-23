require 'pathname'
require 'fileutils'

require_relative '../helpers/tmp_directory'
require_relative './git_repository'
require_relative './i18n_provider'
require_relative './locales_updater_configuration'

ENGLISH_TRANSLATION_FILE = 'en.yml'
ENGLISH_JS_TRANSLATION_FILE = 'js-en.yml'

class LocalesUpdater
  include TmpDirectory

  def update_all_locales_of_all_repos(debug: true)
    repos_to_update = plugins_with_locales

    within_tmp_directory(delete_if_exists: true, debug: debug) do
      repos_to_update.each do |plugin_name, specifics|
        update_i18n_handle(specifics)

        within_tmp_directory(path: File.join(FileUtils.pwd, plugin_name), debug: debug) do
          within_plugin_repo(configuration_hash: specifics, path: FileUtils.pwd, debug: debug) do
            puts "Uploading english for #{plugin_name}"
            upload_english(plugin_name, debug)
            request_build(debug)
            puts "Downloading translations for #{plugin_name}"
            download_and_replace_locales
          end
        end
      end
    end
  end

  private

  def within_plugin_repo(configuration_hash:, path:, debug:)
    setup_plugin_repo(configuration_hash, path)
    @plugin_repo.within_repo do
      yield
    end
    commit_and_push_plugin_repo(debug)
  end

  def plugins_with_locales
    configuration[:plugins]
  end

  def configuration
    LocalesUpdaterConfiguration.configuration
  end

  def update_i18n_handle(configuration_hash)
    @i18n_provider = begin
      project_id = configuration_hash[:project_id]
      api_key = configuration_hash[:api_key]
      version = configuration_hash[:version]
      I18nProvider.new(project_id, api_key, version)
    end
  end

  def setup_plugin_repo(configuration_hash, path)
    uri = configuration_hash[:uri]
    branch = configuration_hash[:branch]
    previous_branch = configuration_hash[:previous_branch]

    @plugin_repo = GitRepository.new(uri, path)
    @plugin_repo.clone

    @plugin_repo.checkout(branch)
    @plugin_repo.merge(previous_branch, strategy: :ours) if previous_branch
    @plugin_repo
  end

  def commit_and_push_plugin_repo(debug)
    @plugin_repo.add('config/locales')
    @plugin_repo.commit('update locales from crowdin')
    @plugin_repo.push unless debug
  end

  def upload_english(plugin_name, debug)
    if debug
      puts 'Skipping uploading english due to debug mode'
      return
    end
    # either add or update the english (js) translation file
    titles = {
      ENGLISH_TRANSLATION_FILE => "#{plugin_name} Wording",
      ENGLISH_JS_TRANSLATION_FILE => "#{plugin_name} JavaScript Wording"
    }
    [ENGLISH_TRANSLATION_FILE, ENGLISH_JS_TRANSLATION_FILE].each do |translation_file|
      path_to_translation = Pathname.new('config') + 'locales' + translation_file
      title = titles[translation_file]
      export_pattern = js_translation?(path_to_translation) ? 'js-%two_letters_code%.yml' : '%two_letters_code%.yml'
      if File.exist?(path_to_translation)
        @i18n_provider.upload_english(translation_file, path_to_translation, title, export_pattern)
      end
    end
  end

  def request_build(debug)
    if debug
      puts 'Skipping requesting build due to debug mode'
      return
    end
    @i18n_provider.request_build
  end

  def download_and_replace_locales
    # todo delete all locales here? maybe for the case that
    # we do not support a language anymore.
    target_directory = Pathname(File.join('config', 'locales'))
    @i18n_provider.each_locale do |entry|
      language_name = entry.name.split('/').first # the file is put in a directory containing the language name

      # only take translations with enough percent translated
      next unless @i18n_provider.translation_status_high_enough?(language_name, acceptance_level)

      filepath = target_directory.join "#{js_translation?(Pathname.new(entry.name)) ? 'js-' : ''}#{language_name}.yml"
      replace_file(filepath, entry)
    end
  end

  def acceptance_level
    return 100 if ENV['ACCEPTANCE_LEVEL'].nil?
    ENV['ACCEPTANCE_LEVEL'].to_i
  end

  def replace_file(filepath, new_file)
    File.delete(filepath) if File.file?(filepath)
    File.open(filepath, 'wb') do |file|
      file.write new_file.get_input_stream.read
    end
  end

  def js_translation?(translation_file_path)
    !!(translation_file_path.basename.to_s[0..-5] =~ /\Ajs-.+\z/)
  end
end
