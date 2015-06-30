# todo those ought to be in the gemspec
require 'tempfile'
require 'crowdin-api'
require 'yaml'
require 'zip'
require 'pathname'
require 'fileutils'

require_relative '../helpers/tmp_directory'
require_relative './git_repository'

class LocalesUpdater
  extend TmpDirectory

  def self.update_all_locales_of_all_repos(debug: true)
    repos_to_update = plugins_with_locales

    tmp_path = create_tmp_directory(delete: true)

    Dir.chdir tmp_path do
      repos_to_update.each do |name, specifics|
        # todo each branch
        uri = specifics[:uri]
        set_crowdin_specifics(specifics)

        FileUtils.rm_rf name
        Dir.mkdir name

        repo_path = name
        git_repo = GitRepository.new(uri, repo_path)
        git_repo.clone_or_pull

        git_repo.checkout(branch)
        # todo or should we merge this branch into the next ('push vs pull')
        git_repo.merge(previous_branch, '-Xours') if previous_branch
        git_repo.within_repo do
          begin
            upload_english
            request_build
            download_and_replace_locales
          rescue Crowdin::API::Errors::Error => e
            puts "Error during update of #{name}: #{e.message}"
          end
          fix_missing_keys
        end
        git_repo.add('config/locales')
        git_repo.commit('update locales from crowdin')
        git_repo.push(branch) unless debug
      end
    end
    delete_tmp_folder(tmp_path) unless debug
  end

  def self.plugins_with_locales
    configuration[:plugins]
  end

  def self.configuration
    # todo raise error if something is missing
    @configuration ||= begin
      configuration_file = Pathname(__FILE__) + '../../../../../'
    configuration_file = configuration_file + 'configuration.yml'
    YAML.load_file(configuration_file)
    end
  end

  def self.set_crowdin_specifics(configuration_hash)
    @project_id = configuration_hash[:project_id]
    @api_key = configuration_hash[:api_key]
    @crowdin_directory = configuration[:crowdin_directory]
  end

  def self.branch
    configuration[:branch]
  end

  def self.previous_branch
    configuration[:previous_branch]
  end

  def self.upload_english
    # create crowdin directory just in case it doesn't exist.
    crowdin = create_crowdin_handle
    dir = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
    unless dir
      crowdin.add_directory(@crowdin_directory)
    end

    # either add or update the english translation file
    path_to_translation = File.join 'config', 'locales', 'en.yml'
    dir = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
    if dir['files'].find {|f| f['name'] == 'en.yml'}
      crowdin.update_file [{dest: "/#{@crowdin_directory}/en.yml", source: path_to_translation.to_s, title: 'OpenProject wording', export_pattern: '%two_letters_code%.yml'}], type: 'yaml'
    else
      crowdin.add_file [{dest: "/#{@crowdin_directory}/en.yml", source: path_to_translation.to_s, title: 'OpenProject wording', export_pattern: '%two_letters_code%.yml'}], type: 'yaml'
    end

    # either add or update the english javascript translation file
    path_to_translation = File.join 'config', 'locales', 'js-en.yml'
    dir = crowdin.project_info['files'].find {|f| f['name'] == @crowdin_directory && f['node_type'] == 'directory'}
    if dir['files'].find {|f| f['name'] == 'js-en.yml'}
      crowdin.update_file [{dest: "/#{@crowdin_directory}/js-en.yml", source: path_to_translation.to_s, title: 'OpenProject JavaScript wording', export_pattern: 'js-%two_letters_code%.yml'}], type: 'yaml'
    else
      crowdin.add_file [{dest: "/#{@crowdin_directory}/js-en.yml", source: path_to_translation.to_s, title: 'OpenProject JavaScript wording', export_pattern: 'js-%two_letters_code%.yml'}], type: 'yaml'
    end
  end

  def self.request_build
    # todo maybe this could run into a timeout?
    crowdin = create_crowdin_handle
    crowdin.export_translations
  end

  def self.create_crowdin_handle
    Crowdin::API.new project_id: @project_id, api_key: @api_key
  end

  def self.download_and_replace_locales
    # todo delete all locales here? maybe for the case that
    # we do not support a language anymore.
    begin
      languages_files = create_temp_file('crowdin_translations')
      download_from_crowding(languages_files.path)

      target_directory = Pathname(File.join('config', 'locales'))
      Zip::File.open(languages_files.path) do |zip_file|
        zip_file.glob("*/#{@crowdin_directory}/*.yml").each do |entry|
          language_name = entry.name.split('/').first # the file is put in a directory containing the language name

          # only take translations with enough percent translated
          # todo do we require 100% here?
          next unless translation_status_high_enough?(language_name, 100)

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

  def self.translation_status_high_enough?(code, percent)
    @translations_statuses ||= begin
      crowdin = create_crowdin_handle
      crowdin.translations_status
    end
    translation_status = @translations_statuses.select do |translation|
      translation['code'] == code
    end
    translation_status.first['translated_progress'].to_i >= percent
  end

  def self.create_temp_file(filename)
    tempfile = Tempfile.new(filename)
    tempfile.close
    tempfile
  end

  def self.download_from_crowding(output)
    # todo what about errors? maybe a timeout?
    crowdin = create_crowdin_handle
    crowdin.download_translation 'all', output: output
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

  def self.delete_tmp_folder(path)
    FileUtils.rm_rf path
  end
end
