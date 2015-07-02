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
    LocalesUpdater.new.update_all_locales_of_all_repos
  end
end
