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

module Redmine
  module I18n

    # Add langauges from this plugin to the list of available languages
    def all_languages_with_translation_plugin
      plugin_languages = Dir[OpenProject::Translations::Engine.root.join('config', 'locales', '*.{rb,yml}').to_s].map do |file_path|
        File.basename(file_path).split('.').first.to_sym
      end

      # do not count javascript translations as separate langauges
      plugin_languages.reject! {|l| l.to_s[0..2] == 'js-' }

      core_languages = all_languages_without_translation_plugin

      (core_languages + plugin_languages).sort.uniq
    end
    alias_method_chain :all_languages, :translation_plugin
  end
end
