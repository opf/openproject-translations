# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'open_project/translations/version'

Gem::Specification.new do |s|
  s.name        = 'openproject-translations'
  s.version     = OpenProject::Translations::VERSION
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.homepage    = 'https://www.openproject.org/projects/translations'
  s.summary     = 'OpenProject Translations'
  s.description = 'Adds translations to OpenProject.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,doc,lib}/**/*'] + %w(README.md)

  s.add_dependency 'rails', '~> 4.2.3'
  s.add_dependency 'rubyzip'
  s.add_dependency 'crowdin-api', '~> 0.4.0'
  s.add_dependency 'mixlib-shellout', '~> 2.1.0'
end
