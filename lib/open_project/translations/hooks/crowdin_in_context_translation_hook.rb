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

module OpenProject::Translations::Hooks
  class CrowdinInContextTranslations < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      if ::I18n.locale == :lol #the in-context translation pseudo-language
        "<script type=\"text/javascript\">
           var _jipt = [];
           _jipt.push(['project', 'openproject']);
         </script>
         <script type=\"text/javascript\" src=\"//cdn.crowdin.com/jipt/jipt.js\"></script>".html_safe
      end
    end
  end
end
