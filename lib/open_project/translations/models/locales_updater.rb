require 'pathname'
require 'fileutils'

require_relative '../helpers/tmp_directory'
require_relative './git_repository'
require_relative './i18n_provider'
require_relative './locales_updater_configuration'

ENGLISH_TRANSLATION_FILE = 'en.yml'
ENGLISH_JS_TRANSLATION_FILE = 'js-en.yml'
ACCEPTANCE_LEVEL = ENV['ACCEPTANCE_LEVEL'].to_i || 100

class LocalesUpdater
  include TmpDirectory

  def update_all_locales_of_all_repos(debug: true)
    repos_to_update = plugins_with_locales

    within_tmp_directory(delete_if_exists: true, debug: debug) do
      repos_to_update.each do |plugin_name, specifics|
        update_i18n_handle(specifics)

        within_tmp_directory(path: File.join(FileUtils.pwd, plugin_name), debug: debug) do
          git_repo = setup_plugin_repo(specifics[:uri], FileUtils.pwd)
          git_repo.within_repo do
            upload_english
            request_build
            download_and_replace_locales
          end
          commit_and_push_plugin_repo(git_repo, debug)
        end
      end
    end
  end

  private

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

  def branch
    configuration[:branch]
  end

  def previous_branch
    configuration[:previous_branch]
  end

  def setup_plugin_repo(uri, path)
    plugin_repo = GitRepository.new(uri, path)
    plugin_repo.clone

    plugin_repo.checkout(branch)
    plugin_repo.merge(previous_branch, strategy: :ours) if previous_branch
    plugin_repo
  end

  def commit_and_push_plugin_repo(plugin_repo, debug)
    plugin_repo.add('config/locales')
    plugin_repo.commit('update locales from crowdin')
    plugin_repo.push(branch) unless debug
  end

  def upload_english
    # either add or update the english (js) translation file
    titles = {
      ENGLISH_TRANSLATION_FILE => 'OpenProject Wording',
      ENGLISH_JS_TRANSLATION_FILE => 'OpenProject JavaScript Wording'
    }
    [ENGLISH_TRANSLATION_FILE, ENGLISH_JS_TRANSLATION_FILE].each do |translation_file|
      path_to_translation = File.join 'config', 'locales', translation_file
      title = titles[translation_file]
      @i18n_provider.upload_english(translation_file, path_to_translation, title)
    end
  end

  def request_build
    @i18n_provider.request_build
  end

  def download_and_replace_locales
    # todo delete all locales here? maybe for the case that
    # we do not support a language anymore.
    target_directory = Pathname(File.join('config', 'locales'))
    @i18n_provider.each_locale do |entry|
      language_name = entry.name.split('/').first # the file is put in a directory containing the language name

      # only take translations with enough percent translated
      next unless @i18n_provider.translation_status_high_enough?(language_name, ACCEPTANCE_LEVEL)

      filepath = target_directory.join "#{js_translation?(Pathname.new(entry.name)) ? 'js-' : ''}#{language_name}.yml"

      File.delete(filepath) if File.file?(filepath)
      File.open(filepath, 'wb') do |file|
        file.write entry.get_input_stream.read
      end
    end
  end

  def js_translation?(translation_file_path)
    !!(translation_file_path.basename.to_s[0..-5] =~ /\Ajs-.+\z/)
  end
end
