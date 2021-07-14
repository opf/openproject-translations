# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/translations/version'

Gem::Specification.new do |s|
  s.name        = "openproject-translations"
  s.version     = OpenProject::Translations::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = 'OpenProject Translations'
  s.description = 'Adds translations to OpenProject.'
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency 'crowdin-api', '~> 0.6.0'
  s.add_dependency 'mixlib-shellout', '~> 2.1.0'
  s.add_dependency 'rubyzip'
end
