# todo those ought to be in the gemspec
require 'tempfile'
require 'crowdin-api'
require 'zip'
require 'pathname'
require 'fileutils'

require_relative '../helpers/tmp_directory'
require_relative './git_repository'
require_relative './i18n_provider'
require_relative './locales_updater_configuration'

ENGLISH_TRANLATION_FILE = 'en.yml'
ENGLISH_JS_TRANLATION_FILE = 'js-en.yml'
ACCEPTANCE_LEVEL = ENV['ACCEPTANCE_LEVEL'] || 100

class LocalesUpdater
  extend TmpDirectory

  def self.update_all_locales_of_all_repos(debug: true)
    repos_to_update = plugins_with_locales

    within_tmp_directory(delete_if_exists: true, debug: debug) do
      repos_to_update.each do |plugin_name, specifics|
        # todo each branch
        create_i18n_handle(specifics)

        within_tmp_directory(path: File.join(FileUtils.pwd, plugin_name), debug: debug) do
          git_repo = setup_plugin_repo(specifics[:uri], FileUtils.pwd)
          git_repo.within_repo do
            # todo rescue should be in provider class
            upload_english
            request_build
            download_and_replace_locales
          end
          git_repo.add('config/locales')
          git_repo.commit('update locales from crowdin')
          git_repo.push(branch) unless debug
        end
      end
    end
  end

  def self.plugins_with_locales
    configuration[:plugins]
  end

  def self.configuration
    LocalesUpdaterConfiguration.configuration
  end

  def self.branch
    configuration[:branch]
  end

  def self.previous_branch
    configuration[:previous_branch]
  end

  def self.setup_plugin_repo(uri, path)
    git_repo = GitRepository.new(uri, path)
    git_repo.clone

    git_repo.checkout(branch)
    # todo or should we merge this branch into the next ('push vs pull')
    git_repo.merge(previous_branch, strategy: :ours) if previous_branch
    git_repo
  end

  def self.create_i18n_handle(configuration_hash)
    @i18n_provider ||= begin
      project_id = configuration_hash[:project_id]
      api_key = configuration_hash[:api_key]
      version = configuration_hash[:version]
      I18nProvider.new(project_id, api_key, version)
    end
  end

  def self.upload_english
    # either add or update the english (js) translation file
    titles = {
      ENGLISH_TRANLATION_FILE => 'OpenProject Wording',
      ENGLISH_JS_TRANLATION_FILE => 'OpenProject JavaScript Wording'
    }
    [ENGLISH_TRANLATION_FILE, ENGLISH_JS_TRANLATION_FILE].each do |translation_file|
      path_to_translation = File.join 'config', 'locales', translation_file
      title = titles[translation_file]
      @i18n_provider.upload_english(translation_file, path_to_translation, title)
    end
  end

  def self.request_build
    @i18n_provider.request_build
  end

  def self.download_and_replace_locales
    # todo delete all locales here? maybe for the case that
    # we do not support a language anymore.
    begin
      languages_files = create_temp_file('crowdin_translations')
      @i18n_provider.download_locales(languages_files.path)

      target_directory = Pathname(File.join('config', 'locales'))
      Zip::File.open(languages_files.path) do |zip_file|
        zip_file.glob("*/#{@crowdin_directory}/*.yml").each do |entry|
          language_name = entry.name.split('/').first # the file is put in a directory containing the language name

          # only take translations with enough percent translated
          # todo do we require 100% here?
          next unless @i18n_provider.translation_status_high_enough?(language_name, ACCEPTANCE_LEVEL)

          filepath = target_directory.join "#{js_translation?(Pathname.new(entry.name)) ? 'js-' : ''}#{language_name}.yml"

          File.delete(filepath) if File.file?(filepath)
          File.open(filepath, 'wb') do |file|
            file.write entry.get_input_stream.read
          end
        end
      end
    ensure
      unlink_temp_file(languages_files)
    end
  end

  def self.create_temp_file(filename)
    tempfile = Tempfile.new(filename)
    tempfile.close
    tempfile
  end

  def self.js_translation?(translation_file_path)
    !!(translation_file_path.basename.to_s[0..-5] =~ /\Ajs-.+\z/)
  end

  def self.unlink_temp_file(tempfile)
    tempfile.unlink
  end

  def self.fix_missing_keys
    # todo this should not be necessary anymore
    # since crowdin already replaces missing keys with
    # the english ones
  end
end
