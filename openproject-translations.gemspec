# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/translations/version'

Gem::Specification.new do |s|
  s.name        = "openproject-translations"
  s.version     = OpenProject::Translations::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/translations"
  s.summary     = 'OpenProject Translations'
  s.description = 'Adds translations to OpenProject.'
  s.license     = "GPLv3" # TODO: determine

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency "rails", "~> 3.2.14"
  s.add_dependency "openproject-plugins", "~> 1.0.6"
  s.add_dependency "httmultiparty"
  s.add_dependency "rubyzip"
  s.add_dependency "rest-client"
end
