#encoding: utf-8
#
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require 'tempfile'
require 'crowdin-api'
require 'yaml'
require 'zip'

namespace :translations do
  crowdin_project_key = ''
  crowdin_project_name = 'openproject'
  # translations are organized in subdirecotries in crowdin.
  # one dir per OpenProject version
  crowdin_directory = ''

  # Whether the .yml file is based on the js-en.yml JavaScript translation file
  def js_translation?(translation_file_path)
    !!(translation_file_path.basename.to_s[0..-5] =~ /\Ajs-.+\z/)
  end

  def previous_version
    current_version = OpenProject::VERSION.to_semver
    # ignoring specials like '-alpha'
    current_version =~ /\A(\d+)\.(\d+)\.(\d+)/
    major = $1.to_i
    minor = $2.to_i
    patch = $3.to_i
    if patch > 0
      "#{major}.#{minor}.#{patch - 1}"
    elsif minor > 0
      # maybe we should be more exact here
      "#{major}.#{minor - 1}.0"
    else
      "#{major - 1}.#{0}.#{0}"
    end
  end

  task :check_for_api_key => :environment do
    env_name = 'OPENPROJECT_CROWDIN_KEY'
    raise "ERROR: please specify a crowdin API key via the #{env_name} environment variable" unless ENV[env_name]
    crowdin_project_key = ENV[env_name]
    crowdin_directory = OpenProject::VERSION.to_semver
  end

  desc "request a new build of the language export files"
  task :request_build => :check_for_api_key do
    crowdin = Crowdin::API.new project_id: crowdin_project_name, api_key: crowdin_project_key
    crowdin.export_translations
  end

  desc "fetch available translations from crowdin, and puts them into this gem"
  task :download => :check_for_api_key do
    unless File.writable? OpenProject::Translations::Engine.root.join 'config', 'locales'
      raise "#{OpenProject::Translations::Engine.root.join 'config', 'locales'} need to be writable"
    end

    # nuke locales directory to get rid of old files
    OpenProject::Translations::Engine.root.join('config', 'locales').children.each do |file|
      File.delete(file) if File.file?(file)
    end

    crowdin = Crowdin::API.new project_id: crowdin_project_name, api_key: crowdin_project_key

    puts 'Downloading translations from crowdin ...'
    begin
      languages_files = Tempfile.new('crowdin_translations')
      languages_files.close

      crowdin = Crowdin::API.new project_id: crowdin_project_name, api_key: crowdin_project_key
      crowdin.download_translation 'all', output: languages_files.path

      # read zip
      target_directory = OpenProject::Translations::Engine.root.join 'config', 'locales'
      Zip::File.open(languages_files.path) do |zip_file|
        zip_file.glob("*/#{crowdin_directory}/*.yml").each do |entry|
          language_name = entry.name.split('/').first # the file is put in a directory containing the language name
          filepath = target_directory.join "#{js_translation?(Pathname.new(entry.name)) ? 'js-' : ''}#{language_name}.yml"
          puts "saving #{filepath.basename}"

          File.delete(filepath) if File.file?(filepath)
          File.open(filepath, 'wb') do |file|
            file.write entry.get_input_stream.read
          end
        end
      end
    ensure
      languages_files.unlink
    end
  end

  desc "Upload current en.yml to crowdin, so that the crowd can update their translations"
  task :upload => :check_for_api_key do
    puts "Uploading current OpenProject en.yml to crowdin"
    crowdin = Crowdin::API.new project_id: crowdin_project_name, api_key: crowdin_project_key

    # create crowdin directory just in case it doesn't exist.
    dir = crowdin.project_info['files'].find {|f| f['name'] == crowdin_directory && f['node_type'] == 'directory'}
    unless dir
      crowdin.add_directory(crowdin_directory)
    end

    # either add or update the english translation file
    path_to_translation = Rails.root.join 'config', 'locales', 'en.yml'
    dir = crowdin.project_info['files'].find {|f| f['name'] == crowdin_directory && f['node_type'] == 'directory'}
    if dir['files'].find {|f| f['name'] == 'en.yml'}
      crowdin.update_file [{dest: "/#{crowdin_directory}/en.yml", source: path_to_translation.to_s, title: 'OpenProject wording', export_pattern: '%two_letters_code%.yml'}], type: 'yaml'
    else
      crowdin.add_file [{dest: "/#{crowdin_directory}/en.yml", source: path_to_translation.to_s, title: 'OpenProject wording', export_pattern: '%two_letters_code%.yml'}], type: 'yaml'
    end

    # either add or update the english javascript translation file
    path_to_translation = Rails.root.join 'config', 'locales', 'js-en.yml'
    dir = crowdin.project_info['files'].find {|f| f['name'] == crowdin_directory && f['node_type'] == 'directory'}
    if dir['files'].find {|f| f['name'] == 'js-en.yml'}
      crowdin.update_file [{dest: "/#{crowdin_directory}/js-en.yml", source: path_to_translation.to_s, title: 'OpenProject JavaScript wording', export_pattern: 'js-%two_letters_code%.yml'}], type: 'yaml'
    else
      crowdin.add_file [{dest: "/#{crowdin_directory}/js-en.yml", source: path_to_translation.to_s, title: 'OpenProject JavaScript wording', export_pattern: 'js-%two_letters_code%.yml'}], type: 'yaml'
    end
  end

  desc "Upload old translations for new version"
  task :upload_old_translations => :check_for_api_key do
    puts 'Uploading old translations for new version'
    begin
      languages_files = Tempfile.new('crowdin_translations')
      languages_files.close

      crowdin = Crowdin::API.new project_id: crowdin_project_name, api_key: crowdin_project_key
      crowdin.download_translation 'all', output: languages_files.path

      Zip::File.open(languages_files.path) do |zip_file|
        zip_file.glob("*/#{previous_version}/*.yml").each do |entry|
          language_name = entry.name.split('/').first # the file is put in a directory containing the language name

          js_prefix = js_translation?(Pathname.new(entry.name)) ? 'js-' : ''
          dest = "/#{crowdin_directory}/#{js_prefix}en.yml"
          locale_temp_file = Tempfile.new('old_locale')
          locale_temp_file.close
          # not pretty but working
          File.delete(locale_temp_file.path) if File.file?(locale_temp_file.path)
          entry.extract locale_temp_file.path
          files = [ {dest: dest, source: locale_temp_file.path} ]
          params = {}

          puts "uploading #{dest}"
          crowdin.upload_translation(files, language_name, params)
        end
      end
    ensure
      languages_files.unlink
    end
  end

  desc "Insert missing translation keys into all translation files. This circumvents a crowdin bug."
  task :fix_missing_keys => :environment do
    puts 'Fixing missing keys and language names...'

    # see: https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
    class ::Hash
      def deep_merge(second)
          merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
          self.merge(second, &merger)
      end
    end

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

    # read english translation keys from the openproject core
    english_translation = YAML.load File.read(Rails.root.join('config', 'locales', 'en.yml'))
    english_js_translation = YAML.load File.read(Rails.root.join('config', 'locales', 'js-en.yml'))

    # fix missing translation keys in all translation files of this gem
    OpenProject::Translations::Engine.root.join('config', 'locales').children.select do |file_path|
      # find all .yml files in this gems' locales directory
      file_path.file? && file_path.extname == '.yml'
    end.each do |translation_file|
      language_key = calculate_language_key translation_file

      puts "fixing #{js_translation?(translation_file) ? 'js-' : ''}#{language_key}"

      # work around a crowdin bug which inserts inapropriate whitespace for the in-context localization file
      translation_yaml = File.read translation_file
      if language_key == 'lol'
        translation_yaml.gsub! /precision:0/, 'precision: 0'
      end
      # for each translation file add missing translation keys
      translation = YAML.load translation_yaml

      # add missing english keys
      if js_translation?(translation_file)
        translation = {language_key => english_js_translation['en'].deep_merge(translation.values.first)}
      else
        translation = {language_key => english_translation['en'].deep_merge(translation.values.first)}
      end

      # write file back to disk
      File.open(translation_file, 'w') do |file|
        file.write translation.to_yaml
      end
      # the files should be named like their translation-key
      File.rename translation_file, OpenProject::Translations::Engine.root.join('config', 'locales', "#{js_translation?(translation_file) ? 'js-' : ''}#{language_key}.yml")
    end
  end
end
