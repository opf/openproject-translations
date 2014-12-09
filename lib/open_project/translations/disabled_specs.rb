if Rails.env.test?
  require 'rspec/example_disabler'
  RSpec::ExampleDisabler.disable_example('I18n all_languages has a language for every language file', 'plugin openproject-translations changes behavior')
end
