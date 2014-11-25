//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.md for more details.
//++

// extra locales, automatically loaded
var requireExtraLocale = require.context('./config/locales', false, /js-[\w|-]{2,5}\.yml$/);
requireExtraLocale.keys().forEach(function(localeFile) {
  var locale = localeFile.match(/js-([\w|-]{2,5})\.yml/)[1];
  I18n.translations[locale] = requireExtraLocale(localeFile)[locale];
});
