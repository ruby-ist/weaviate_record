# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Bm25 do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Bm25
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  describe '#bm25' do
    context 'when text is not a string' do
      it 'raises a TypeError' do
        expect { instance.bm25(1) }.to raise_error(TypeError, 'text must be a string')
      end
    end

    context 'when text is present' do
      it 'sets the keyword_search' do
        instance.bm25('test')
        expect(instance.instance_variable_get(:@keyword_search)).to eq('test')
      end
    end

    context 'when text is not present' do
      it 'does not set the keyword_search' do
        instance.bm25('')
        expect(instance.instance_variable_get(:@keyword_search)).to be_nil
      end
    end

    it 'sets loaded to false' do
      instance.bm25('test')
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.bm25('test')).to eq(instance)
    end

    # context 'On queries' do
    #   let!(:documents) do
    #     [
    #       DocumentTest.create(content: 'Social security number is needed'),
    #       DocumentTest.create(content: 'Social awareness programme'),
    #       DocumentTest.create(content: 'Sherlock is a not a social person')
    #     ]
    #   end
    #   after { documents.each(&:destroy) }

    #   it 'returns the documents matching the keyword' do
    #     expect(DocumentTest.bm25('social').map(&:id)).to match_array(documents.map(&:id))
    #     expect(DocumentTest.bm25('security number').map(&:id).first).to eq(documents[0].id)
    #   end
    # end
  end
end
