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
     def all_languages_with_translation_plugin
      all_languages_without_translation_plugin +
        Dir[OpenProject::Translations::Engine.root.join('config', 'locales', '*.{rb,yml}').to_s].map do |f|
          File.basename(f).split('.').first.to_sym
        end
    end
    alias_method_chain :all_languages, :translation_plugin
  end
end
