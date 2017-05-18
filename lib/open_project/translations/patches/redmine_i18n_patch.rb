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

module OpenProject::Translations::Patches::RedmineI18nPatch
  # Add langauges from this plugin to the list of available languages
  def all_languages
    plugin_languages = Dir[OpenProject::Translations::Engine.root.join('config', 'locales', '*.{yml}').to_s].map do |file_path|
      File.basename(file_path).split('.').first.to_sym
    end

    # do not count javascript translations as separate languages
    plugin_languages.reject! { |l| l.to_s[0..2] == 'js-' }

    core_languages = super

    (core_languages + plugin_languages).sort.uniq
  end
end

module Redmine
  module I18n
    prepend OpenProject::Translations::Patches::RedmineI18nPatch
  end
end
