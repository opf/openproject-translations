require 'spec_helper'
require_relative '../../../lib/open_project/translations/models/locales_updater'

describe LocalesUpdater do
  let(:locales_updater) { LocalesUpdater.new }
  let(:configuration) {
    { :plugins =>
      { 'test-project' =>
        {
          uri: uri,
          api_key: api_key,
          project_id: project_id,
          version: version
        }
      }
    }
  }
  let(:uri) { 'test-uri' }
  let(:api_key) { 'test-key' }
  let(:project_id) { 'test-id' }
  let(:version) { 'test-version' }

  describe '#update_all_locales_of_all_repos' do
    before do
      allow(LocalesUpdaterConfiguration).to receive(:configuration).and_return(configuration)
      allow(locales_updater).to receive(:within_tmp_directory).and_yield
    end

    it 'uses the correct credentials' do
      allow(locales_updater).to receive(:within_plugin_repo)

      expect(I18nProvider).to receive(:new).with(project_id, api_key, version)
      locales_updater.update_all_locales_of_all_repos
    end

    let(:i18n_provider) { instance_double(I18nProvider) }
    it 'uploads the english file' do
      allow(locales_updater).to receive(:within_plugin_repo).and_yield
      allow(locales_updater).to receive(:request_build)
      allow(locales_updater).to receive(:download_and_replace_locales)
      allow(locales_updater).to receive(:update_i18n_handle)
      locales_updater.instance_variable_set(:@i18n_provider, i18n_provider)

      expect(i18n_provider).to receive(:upload_english).twice
      locales_updater.update_all_locales_of_all_repos
    end

    let(:entry) { instance_double(Zip::Entry) }
    let(:entry_name) { 'en/version/en.yml' }
    it 'checks if the translation status is high enough' do
      # call me the mockingbird
      allow(locales_updater).to receive(:within_plugin_repo).and_yield
      allow(locales_updater).to receive(:upload_english)
      allow(locales_updater).to receive(:request_build)
      allow(locales_updater).to receive(:update_i18n_handle)
      allow(locales_updater).to receive(:replace_file)
      allow(i18n_provider).to receive(:each_locale).and_yield(entry)
      allow(entry).to receive(:name).and_return(entry_name)

      locales_updater.instance_variable_set(:@i18n_provider, i18n_provider)

      expect(i18n_provider).to receive(:translation_status_high_enough?).with('en', 100)
      locales_updater.update_all_locales_of_all_repos
    end

    it 'replaces the locales with the ones from the I18nProvider' do
      allow(locales_updater).to receive(:within_plugin_repo).and_yield
      allow(locales_updater).to receive(:upload_english)
      allow(locales_updater).to receive(:request_build)
      allow(locales_updater).to receive(:update_i18n_handle)
      allow(i18n_provider).to receive(:translation_status_high_enough?).and_return(true)
      allow(i18n_provider).to receive(:each_locale).and_yield(entry)
      allow(entry).to receive(:name).and_return(entry_name)

      locales_updater.instance_variable_set(:@i18n_provider, i18n_provider)

      expect(locales_updater).to receive(:replace_file)
      locales_updater.update_all_locales_of_all_repos
    end

    let(:plugin_repo) { instance_double(GitRepository) }
    it 'adds, commits and pushes changes to the repo' do
      allow(locales_updater).to receive(:upload_english)
      allow(locales_updater).to receive(:request_build)
      allow(locales_updater).to receive(:download_and_replace_locales)
      allow(locales_updater).to receive(:setup_plugin_repo)
      allow(plugin_repo).to receive(:within_repo)

      locales_updater.instance_variable_set(:@plugin_repo, plugin_repo)

      expect(plugin_repo).to receive(:add)
      expect(plugin_repo).to receive(:commit)
      expect(plugin_repo).to receive(:push)
      locales_updater.update_all_locales_of_all_repos(debug: false)
    end
  end
end
