# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Bm25 do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Bm25
    end
  end
  let(:instance) { klass.new }

  describe '#bm25' do
    context 'when text is not a string' do
      it 'raises an error' do
        expect { instance.bm25(1) }.to raise_error(NoMethodError, "undefined method `to_str' for 1:Integer")
      end
    end

    context 'when text is present' do
      it 'sets the keyword_search' do
        instance.bm25('test')
        expect(instance.instance_variable_get(:@keyword_search)).to eq('{ query: "test" }')
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

    context 'with queries' do
      let!(:articles) do
        [
          Article.create(content: 'Social security number is needed'),
          Article.create(content: 'Social awareness programme'),
          Article.create(content: 'Sherlock is a not a social person')
        ]
      end

      after { articles.each(&:destroy) }

      it 'returns the articles matching the keyword' do
        expect(Article.bm25('security number').map(&:id).first).to eq(articles[0].id)
      end
    end
  end
end
