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

require 'open_project/plugins'

module OpenProject::Translations
  class Engine < ::Rails::Engine
    engine_name :openproject_translations

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-translations',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 4.0.0'

    patches [ :ApplicationHelper ]

    # load custom translation rules, as stored in config/locales/plurals.rb
    # to be aware of e.g. Japanese not having a plural from for nouns
    initializer 'translation.pluralization.rules' do
      require 'open_project/translations/pluralization_backend'
      I18n::Backend::Simple.send(:include, OpenProject::Translations::PluralizationBackend)
    end

    config.to_prepare do
      # the patches helper does not work for patches in the Redmine module, so we patch things manually now
      Redmine::I18n # let rails do some autoloading magic with Redmine::I18n
      require_dependency 'open_project/translations/patches'
      require_dependency 'open_project/translations/patches/redmine_i18n_patch'
    end

    initializer 'translations.hooks' do
      require_dependency 'open_project/translations/hooks'
      require_dependency 'open_project/translations/hooks/crowdin_in_context_translation_hook'
    end
  end
end
