require 'spec_helper'
require_relative '../../../lib/open_project/translations/helpers/run_command'

describe RunCommand do
  include described_class
  describe '#run_command' do
    let(:result) { 'test-value' }
    let(:command) { "echo '#{result}'" }

    it 'returns the correct value' do
      expect(run_command(command)).to eql(result)
    end

    context 'with a command that fails' do
      let(:command) { "ech 'test'" }

      it 'raises an error' do
        expect { run_command(command) }.to raise_error(/command/)
      end
    end
  end
end
