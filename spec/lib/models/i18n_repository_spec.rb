require 'spec_helper'
require_relative '../../../lib/open_project/translations/models/i18n_provider'

describe I18nProvider do
  let(:i18n_provider) { described_class.new(project_id, api_key, crowdin_directory, previous_crowdin_directory) }
  let(:project_id) { 'test-id' }
  let(:api_key) { 'test-api-key' }
  let(:crowdin_directory) { 'test-directory' }
  let(:previous_crowdin_directory) { 'previous_directory' }
  let(:crowdin) { instance_double(Crowdin::API) }

  describe '#initialize' do
    it 'initializes the Crowdin api with correct arguments' do
      expect(Crowdin::API).to receive(:new).with(project_id: project_id, api_key: api_key)
      i18n_provider
    end
  end

  describe '#create_handle' do
    it 'returns an instance of Crowdin::API' do
      expect(i18n_provider.create_handle).to be_an_instance_of(Crowdin::API)
    end
  end

  describe '#upload_english' do
    let(:crowdin) { instance_double(Crowdin::API) }
    let(:translation_file) { 'test-file' }
    let(:path_to_translation) { 'test-path' }
    let(:title) { 'test-title' }
    let(:export_pattern) { '' }

    it 'creates crowdin directory if missing' do
      allow(i18n_provider).to receive(:file_exists_in_directory?).and_return(true)
      allow(i18n_provider).to receive(:update_file)

      expect(i18n_provider).to receive(:add_directory_if_missing)
      i18n_provider.upload_english(translation_file, path_to_translation, title, export_pattern)
    end

    context 'with the file already on Crowdin' do
      before do
        allow(i18n_provider).to receive(:file_exists_in_directory?).and_return(true)
      end

      it 'updates the file on Crowdin' do
        allow(i18n_provider).to receive(:add_directory_if_missing)

        expect(i18n_provider).to receive(:update_file)
        i18n_provider.upload_english(translation_file, path_to_translation, title, export_pattern)
      end
    end

    context 'with the file not already on Crowdin' do
      before do
        allow(i18n_provider).to receive(:file_exists_in_directory?).and_return(false)
      end

      it 'updates the file on Crowdin' do
        allow(i18n_provider).to receive(:add_directory_if_missing)

        expect(i18n_provider).to receive(:add_file)
        i18n_provider.upload_english(translation_file, path_to_translation, title, export_pattern)
      end
    end
  end

  describe '#add_directory_if_missing' do
    context 'with the directory missing on Crowdin' do
      before do
        allow(i18n_provider).to receive(:crowdin_directory_exists?).and_return(false)
        i18n_provider.instance_variable_set(:@crowdin, crowdin)
      end

      it 'triggers the creation of the directory on Crowding' do
        expect(crowdin).to receive(:add_directory).with(crowdin_directory)
        i18n_provider.add_directory_if_missing
      end
    end
  end

  describe '#request_build' do
    before do
      i18n_provider.instance_variable_set(:@crowdin, crowdin)
    end

    it 'triggers the export of translations' do
      expect(crowdin).to receive(:export_translations)
      i18n_provider.request_build
    end
  end

  describe '#download_locales' do
    let(:path) { 'test-path' }

    before do
      i18n_provider.instance_variable_set(:@crowdin, crowdin)
    end

    it 'triggers the download to the correct path' do
      expect(crowdin).to receive(:download_translation).with('all', output: path)
      i18n_provider.download_locales(path)
    end
  end

  describe '#translation_status_high_enough?' do
    let(:code) { 'test-code' }
    let(:percent) { 100 }
    let(:translations_statuses) { [ { 'code' => code, 'translated_progress' => percent } ] }

    before do
      i18n_provider.instance_variable_set(:@translations_statuses, translations_statuses)
    end

    context 'with the translation status being to low' do
      let(:acceptance_leve) { 101 }

      it 'returns false' do
        expect(i18n_provider.translation_status_high_enough?(code, acceptance_leve) ).to be_falsey
      end
    end

    context 'with the translation status being high enough' do
      let(:acceptance_leve) { 99 }

      it 'returns false' do
        expect(i18n_provider.translation_status_high_enough?(code, acceptance_leve) ).to be_truthy
      end
    end


    context 'when @tranlation_statuses is nil' do
      let(:translations_statuses) { nil }

      before do
        i18n_provider.instance_variable_set(:@crowdin, crowdin)
      end

      it 'gets the translation status from Crowdin' do
        expect(crowdin).to receive(:translations_status).and_return([])
        i18n_provider.translation_status_high_enough?(code, percent)
      end
    end
  end

  describe '#each_locale' do
    let(:zip_file) { instance_double(Zip::File) }
    let(:entry1) { 'entry-1' }
    let(:entry2) { 'entry-2' }

    it 'applies the given block to each locale file' do
      allow(i18n_provider).to receive(:download_locales)
      allow(Zip::File).to receive(:open).and_yield(zip_file)
      allow(zip_file).to receive(:glob).and_return([entry1, entry2])
      check = 0
      block = lambda do |entry|
        check += 1 if entry == entry1 || entry == entry2
      end

      i18n_provider.each_locale &block
      expect(check).to eql(2)
    end
  end
end
