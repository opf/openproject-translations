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

require_relative '../open_project/translations/models/locales_updater'

namespace :translations_for_plugins do
  desc "todo, upload english, download locales, commit to plugin repo"
  task :update do
    unless ENV.key? 'OPENPROJECT_TRANSLATIONS_CONFIGURATION_FILE'
      raise "Missing ENV 'OPENPROJECT_TRANSLATIONS_CONFIGURATION_FILE' for version to upload plugins files for."
    end

    unless File.readable? ENV['OPENPROJECT_TRANSLATIONS_CONFIGURATION_FILE']
      raise "Configuration file is not readable."
    end

    unless ENV.key? 'OPENPROJECT_TRANSLATIONS_BRANCH'
      raise "Missing ENV 'OPENPROJECT_TRANSLATIONS_BRANCH' for the branch to upload plugins files from."
    end

    LocalesUpdater.new.update_all_locales_of_all_repos(debug: false)
  end
end
