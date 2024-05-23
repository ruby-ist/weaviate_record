# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Limit do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Limit
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  describe '#limit' do
    it 'raises error for non-numeric values' do
      expect { instance.limit('x') }.to raise_error(TypeError)
    end

    it 'sets the limit instance variable' do
      instance.limit(1)
      expect(instance.instance_variable_get(:@limit)).to eq(1)
    end

    it 'sets loaded to false' do
      instance.loaded = true
      instance.limit(3)
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.limit(1)).to be(instance)
    end

    # context 'On queries' do
    #   let!(:documents) do
    #     10.times.map do |index|
    #       DocumentTest.create(title: "test document #{index}")
    #     end
    #   end
    #   after { documents.each(&:destroy) }

    #   context 'when the given limit is less than total record' do
    #     it 'restricts the number of records' do
    #       expect(DocumentTest.limit(2).to_a.count).to eq(2)
    #       expect(DocumentTest.limit(5).to_a.count).to eq(5)
    #     end
    #   end

    #   context 'when the given limit is greater than total record' do
    #     it 'returns all the records' do
    #       expect(DocumentTest.limit(15).count).to eq(10)
    #     end
    #   end
    # end
  end
end
