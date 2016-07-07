# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/translations/version'

Gem::Specification.new do |s|
  s.name        = "openproject-translations"
  s.version     = OpenProject::Translations::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/translations"
  s.summary     = 'OpenProject Translations'
  s.description = 'Adds translations to OpenProject.'
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency 'rails', '~> 4.2.3'
  s.add_dependency "rubyzip"
  # fixing rest-client to 1.x to prevent CI from updating it to incompatible 2.x
  # as crowdin-api which it is a dependency to does not limit the version
  s.add_dependency 'rest-client', '~> 1.8' 
  s.add_dependency 'crowdin-api', '~> 0.4.0'
  s.add_dependency 'mixlib-shellout', '~> 2.1.0'
end
