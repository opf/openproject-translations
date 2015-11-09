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

require_dependency 'application_helper'

module OpenProject::Translations::Patches
  module ApplicationHelperPatch
    def self.included(base)
      base.class_eval do
        def all_lang_options_for_select_with_translation_plugin(blank = true)
          lang_options = all_lang_options_for_select_without_translation_plugin(blank)

          # rename in-context translation language name for the language select box
          lang_options.map do |lang_name, lang_code|
            if lang_code == OpenProject::Translations::IN_CONTEXT_TRANSLATION_CODE &&
               ::I18n.locale != OpenProject::Translations::IN_CONTEXT_TRANSLATION_CODE
              [OpenProject::Translations::IN_CONTEXT_TRANSLATION_NAME, lang_code]
            else
              [lang_name, lang_code]
            end
          end
        end
        alias_method_chain :all_lang_options_for_select, :translation_plugin

        def lang_options_for_select_with_translation_plugin(blank = true)
          lang_options = lang_options_for_select_without_translation_plugin(blank)
          # rename in-context translation language name for the language select box
          lang_options.map do |lang_name, lang_code|
            if lang_code == OpenProject::Translations::IN_CONTEXT_TRANSLATION_CODE &&
               ::I18n.locale != OpenProject::Translations::IN_CONTEXT_TRANSLATION_CODE
              [OpenProject::Translations::IN_CONTEXT_TRANSLATION_NAME, lang_code]
            else
              [lang_name, lang_code]
            end
          end
        end
        alias_method_chain :lang_options_for_select, :translation_plugin
      end
    end
  end
end
