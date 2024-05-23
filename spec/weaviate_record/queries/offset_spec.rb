# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Offset do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Offset
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  describe '#offset' do
    it 'raises error for non-numeric values' do
      expect { instance.offset('x') }.to raise_error(TypeError)
    end

    it 'sets the offset instance variable' do
      instance.offset(1)
      expect(instance.instance_variable_get(:@offset)).to eq(1)
    end

    it 'sets loaded to false' do
      instance.loaded = true
      instance.offset(3)
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.offset(1)).to be(instance)
    end

    # context 'On queries' do
    #   let!(:documents) do
    #     10.times.map do |index|
    #       DocumentTest.create(title: "test document #{index}")
    #     end
    #   end
    #   after { documents.each(&:destroy) }

    #   context 'when the given offset is less than total record' do
    #     it 'skips the specified number of records' do
    #       expect(DocumentTest.offset(2).order(:title).first.title).to eq('test document 2')
    #       expect(DocumentTest.offset(5).order(:title).first.title).to eq('test document 5')
    #     end
    #   end

    #   context 'when the given offset is greater than total record' do
    #     it 'return empty array' do
    #       expect(DocumentTest.offset(15).all).to be_empty
    #     end
    #   end
    # end
  end
end
