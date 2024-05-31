# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Ask do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Ask
    end
  end
  let(:instance) { klass.new }

  describe '#ask' do
    it 'returns self' do
      expect(instance.ask('What is the capital of France?')).to be(instance)
    end

    it 'sets @ask to question' do
      instance.ask('What is the capital of France?')
      expect(instance.instance_variable_get(:@ask)).to eql('{ question: "What is the capital of France?" }')
    end

    it 'sets @loaded to false' do
      instance.ask('What is the capital of France?')
      expect(instance.instance_variable_get(:@loaded)).to be false
    end
  end
end
