require 'spec_helper'
require_relative '../../../lib/open_project/translations/models/locales_updater'

describe LocalesUpdaterConfiguration do
  describe '.configuration' do
    context 'with a configuration without :plugins key' do
      it 'raises an error' do
        LocalesUpdaterConfiguration.instance_variable_set(:@configuration, {})
        expect{ LocalesUpdaterConfiguration.configuration }.to raise_error(/plugins/)
      end
    end

    let(:configuration) do
      hash = { plugins: {'test' => {} } }
      LocalesUpdaterConfiguration::REQUIRED_KEYS.each do |key|
        hash[:plugins]['test'][key] = 'test'
      end
      hash
    end

    LocalesUpdaterConfiguration::REQUIRED_KEYS.each do |key|
      context "with a configuration without '#{key}' key" do
          let(:altered_configuration) do
            hash = configuration
            hash[:plugins]['test'][key] = nil
            hash
          end

        it 'raises an error' do
          LocalesUpdaterConfiguration.instance_variable_set(:@configuration,
                                                            altered_configuration)
          expect{ LocalesUpdaterConfiguration.configuration }.to raise_error(/#{key}/)
        end
      end
    end
  end
end
