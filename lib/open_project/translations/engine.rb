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

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::Translations
  class Engine < ::Rails::Engine
    engine_name :openproject_translations

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-translations',
             :author_url => 'https://openproject.org',
             :requires_openproject => '>= 4.0.0'

    config.to_prepare do
      require_dependency 'open_project/translations/patches'
      require_dependency 'open_project/translations/patches/redmine_i18n_patch'
    end
  end
end
