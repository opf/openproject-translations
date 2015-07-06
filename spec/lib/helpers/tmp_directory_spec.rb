require 'spec_helper'
require_relative '../../../lib/open_project/translations/helpers/tmp_directory'

describe TmpDirectory do
  include described_class

  describe '#within_tmp_directory' do
    let(:path) { 'test-path' }

    it 'executes the block in the correct directory' do
      allow(self).to receive(:create_tmp_directory)
      allow(self).to receive(:remove_tmp_directory)
      expect(Dir).to receive(:chdir).with(path)
      within_tmp_directory(path: path)
    end

    it 'passes the block to chdir' do
      check = false
      block = lambda do
        check = true
      end
      allow(self).to receive(:create_tmp_directory)
      allow(self).to receive(:remove_tmp_directory)
      expect(Dir).to receive(:chdir).and_yield

      within_tmp_directory &block
      expect(check).to be_truthy
    end
  end

  describe '#create_tmp_directory' do
    let(:path) { File.join(FileUtils.pwd, 'tmp') }

    it 'triggers the creation of a folder' do
      expect(FileUtils).to receive(:mkdir_p).with(path)
      create_tmp_directory
    end

    it 'returns the path to the folder' do
      allow(FileUtils).to receive(:mkdir_p)
      expect(create_tmp_directory).to eql(path)
    end

    context 'when deleting existing folder is enabled' do
      it 'triggers the deletion of the folder' do
        expect(self).to receive(:remove_tmp_directory).with(path)
        create_tmp_directory(delete_if_exists: true)
      end
    end

    context 'with a path specified' do
      let(:path) { 'test-path' }

      it 'triggers the creation of a folder with that path' do
        expect(FileUtils).to receive(:mkdir_p).with(path)
        create_tmp_directory(path: path)
      end

      it 'returns the correct path' do
        allow(FileUtils).to receive(:mkdir_p)
        expect(create_tmp_directory(path: path)).to eql(path)
      end
    end
  end

  describe '#remove_tmp_directory' do
    let(:path) { 'test-path' }

    it 'triggers the deletion of the folder' do
      expect(FileUtils).to receive(:rm_rf).with(path)
      remove_tmp_directory(path)
    end
  end
end
