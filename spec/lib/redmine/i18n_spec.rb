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

require 'redmine/i18n'
require 'spec_helper'

describe Redmine::I18n, type: :helper do
  describe '.all_languages' do
    it 'has a language for every language file' do
      lang_files = (plugin_lang_files + core_lang_files).uniq

      expect(all_languages.size).to eql lang_files.size
    end

    def plugin_lang_files
      Dir.glob(OpenProject::Translations::Engine.root.join('config/locales/*.yml'))
        .map { |f| File.basename(f) }
        .reject { |b| b.starts_with? 'js' }
    end

    def core_lang_files
      Dir.glob(Rails.root.join('config/locales/*.yml'))
        .map { |f| File.basename(f) }
        .reject { |b| b.starts_with?('js') || b.include?('seeder') }
    end
  end
end
