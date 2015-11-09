require 'spec_helper'
require_relative '../../../lib/open_project/translations/models/git_repository'

describe GitRepository do
  # subject { instance_double('GitRepository') }
  subject { GitRepository.new(uri, path) }
  let(:uri) { 'test-url' }
  let(:path) { 'test-path' }

  describe '#initialize' do
    it 'sets the instance variables correctly' do
      instance_variable_uri = subject.instance_variable_get(:@uri)
      instance_variable_path = subject.instance_variable_get(:@path)

      expect(instance_variable_uri). to eql(uri)
      expect(instance_variable_path). to eql(path)
    end
  end

  describe '#clone' do
    it 'calls run_command with correct parameters' do
      expect(subject).to receive(:run_command).with("git clone #{uri} #{path}")
      subject.clone
    end
  end

  describe '#checkout' do
    let(:ref) { 'test-ref' }

    it 'calls run_command with correct parameters' do
      allow(subject).to receive(:within_repo).and_yield

      expect(subject).to receive(:run_command).with("git checkout --force '#{ref}' --")
      subject.checkout(ref)
    end

    it 'runs a command inside the repo' do
      expect(subject).to receive(:within_repo)
      subject.checkout(ref)
    end
  end

  describe '#within_repo' do
    it 'executes the block within the correct directory' do
      check = false
      block = lambda do
        check = true
      end

      allow(Dir).to receive(:chdir).with(path).and_yield
      subject.within_repo &block

      expect(check).to be_truthy
    end
  end

  describe '#add' do
    let(:add_ref) { 'test-ref' }

    it 'calls run_command with correct parameters' do
      allow(subject).to receive(:within_repo).and_yield
      expect(subject).to receive(:run_command).with("git add #{add_ref}")
      subject.add(add_ref)
    end
  end

  describe '#commit' do
    let(:commit_message) { 'test-message' }

    it 'calls run_command with correct parameters' do
      allow(subject).to receive(:within_repo).and_yield
      expect(subject).to receive(:run_command).with("git commit -m '#{commit_message}'")
      subject.commit(commit_message)
    end
  end

  describe '#push' do
    it 'calls run_command with correct parameters' do
      allow(subject).to receive(:within_repo).and_yield
      expect(subject).to receive(:run_command).with('git push')
      subject.push
    end

    context 'with pushing tags' do
      it 'calls run_command with correct parameters' do
        allow(subject).to receive(:within_repo).and_yield
        expect(subject).to receive(:run_command).with('git push --tags')
        subject.push(true)
      end
    end
  end

  describe '#branch' do
    let(:branch) { 'test-branch' }
    it 'returns the correct branch' do
      allow(subject).to receive(:within_repo).and_yield
      allow(subject).to receive(:run_command).and_return(branch)
      expect(subject.branch).to eql(branch)
    end
  end
end
