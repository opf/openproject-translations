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
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency 'rails', '~> 4.0.13'
  s.add_dependency "rubyzip"
  s.add_dependency 'crowdin-api', '~> 0.2.4'
  s.add_dependency 'mixlib-shellout', '~> 2.1.0'
end
