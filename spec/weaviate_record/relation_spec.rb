# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Relation do
  describe '#initialize' do
    it 'cannot be created without collection name' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'accepts collection name as first argument' do
      expect(described_class.new('Article')).to be_an_instance_of(described_class)
    end

    it 'accepts collection class as first argument' do
      expect(described_class.new(Article)).to be_an_instance_of(described_class)
    end

    it 'sets instance variables' do # rubocop:disable RSpec/MultipleExpectations
      article = described_class.new('Article')
      expect(article.instance_variable_get(:@select_options)).to eq({ attributes: [], nested_attributes: {} })
      expect(article.instance_variable_get(:@near_text_options)).to eq({ concepts: [],
                                                                         distance: WeaviateRecord.config
                                                                           .similarity_search_threshold })
      expect(article.instance_variable_get(:@limit)).to eq(25)
      expect(article.instance_variable_get(:@offset)).to eq(0)
      expect(article.instance_variable_get(:@klass)).to eq('Article')
      expect(article.instance_variable_get(:@records)).to eq([])
      expect(article.instance_variable_get(:@loaded)).to be_falsey
      expect(article.instance_variable_get(:@connection)).to be_instance_of(WeaviateRecord::Connection)
    end
    # rubocop:enable RSpec/ExampleLength
  end

  context 'when delegating methods' do
    let(:relation) { described_class.new(Article) }

    it 'delegates empty? to records' do
      expect(relation.send(:records)).to receive(:empty?)
      relation.empty?
    end

    it 'delegates present? to records' do
      expect(relation.send(:records)).to receive(:present?)
      relation.present?
    end
  end

  describe '#each' do
    let(:relation) { described_class.new(Article).select(:content, :categories).limit(3) }

    it 'returns an Enumerator' do
      expect(relation.each).to be_an_instance_of(Enumerator)
    end

    it 'yields the record' do
      article = Article.create(title: 'fun', content: 'lorem ipsum 1', categories: ['test'])
      expect(relation).to all(be_an_instance_of(Article))
      article.destroy
    end
  end

  describe '#destory_all' do
    let(:relation) { described_class.new(Article) }

    context 'when called with out where condition' do
      it 'raises error' do
        expect do
          relation.destroy_all
        end.to raise_error(WeaviateRecord::Errors::MissingWhereCondition,
                           'must specifiy atleast one where condition')
      end
    end

    context 'when called with where condition' do
      it 'calls #delete_where on connection' do
        expect(relation.instance_variable_get(:@connection)).to receive(:delete_where).and_call_original
        relation.where(title: 'fun').destroy_all
      end

      context 'when records deleted successfully' do
        let(:result) { { 'results' => { 'success' => true } } }

        before do
          allow(relation.instance_variable_get(:@connection)).to receive(:delete_where).and_return(result)
        end

        it 'returns the batch deletion result' do
          expect(relation.where(title: 'fun').destroy_all).to eq({ 'success' => true })
        end
      end

      context 'when any error happens in request' do
        let(:result) { { 'error' => { 'message' => 'Server Error' } } }

        before do
          allow(relation.instance_variable_get(:@connection)).to receive(:delete_where).and_return(result)
        end

        it 'raises custom error with error message' do
          expect do
            relation.where(title: 'fun').destroy_all
          end.to raise_error(WeaviateRecord::Errors::ServerError, 'Server Error')
        end
      end

      context 'when delete_where request returns empty string' do
        let(:result) { '' }

        before do
          allow(relation.instance_variable_get(:@connection)).to receive(:delete_where).and_return(result)
        end

        it 'raises unauthorized error' do
          expect do
            relation.where(title: 'fun').destroy_all
          end.to raise_error(WeaviateRecord::Errors::ServerError, 'Unauthorized')
        end
      end

      it 'deletes the record' do
        3.times do |index|
          Article.create(title: 'fun', content: "lorem ipsum #{index}", categories: ['test'])
        end
        expect { relation.where(title: 'fun').destroy_all }.to change(Article, :count).by(-3)
      end
    end
  end

  describe '#inspect' do
    let(:relation) { described_class.new(Article) }

    it 'calls #records' do
      expect(relation).to receive(:records).and_call_original
      relation.inspect
    end

    context 'when called' do
      let!(:articles) do
        [
          Article.create(title: 'article', content: 'lorem ipsum 1', categories: ['test']),
          Article.create(title: 'article', content: 'lorem ipsum 2', categories: ['test'])
        ]
      end

      after { articles.each(&:destroy) }

      it 'returns the records' do
        result = relation.inspect
        expect(result.map(&:id)).to match_array(articles.map(&:id))
      end
    end

    context 'when #records throws error' do
      it 'returns the error object' do
        allow(relation).to receive(:records).and_raise(StandardError, 'Error while fetching records')
        expect(relation.inspect.to_s).to eq(StandardError.new('Error while fetching records').to_s)
      end
    end

    it 'has alias method :all' do
      expect(relation.method(:inspect)).to eq(relation.method(:all))
    end

    it 'has alias method :to_a' do
      expect(relation.method(:inspect)).to eq(relation.method(:to_a))
    end
  end

  describe '#records' do
    let(:relation) { described_class.new(Article) }

    context 'when loaded' do
      before do
        relation.instance_variable_set(:@loaded, true)
        relation.instance_variable_set(:@records, %w[abc def])
      end

      it 'returns records' do
        expect(relation.instance_variable_get(:@records)).to eq(%w[abc def])
      end
    end

    context 'when not loaded' do
      it 'calls to_query' do
        relation = described_class.new(Article)
        expect(relation).to receive(:to_query).and_call_original
        relation.send(:records)
      end

      context 'when fields are present' do
        it 'calls create_or_process_select_fields with true' do
          relation.select(:categories, :content)
          expect(relation).to receive(:create_or_process_select_attributes).with(true, 'categories content')
          relation.send(:records)
        end
      end

      context 'when fields are not present' do
        it 'calls create_or_process_select_fields with false' do
          expect(relation).to receive(:create_or_process_select_attributes).with(false, '')
          relation.send(:records)
        end
      end

      it 'makes a query call' do
        relation.select(:content, :categories)
        expect_any_instance_of(Weaviate::Query).to receive(:get).with(**relation.to_query).and_call_original
        relation.send(:records)
      end

      it 'sets loaded to true' do
        relation.send(:records)
        expect(relation.instance_variable_get(:@loaded)).to be_truthy
      end

      context 'when records are present' do
        let!(:articles) do
          5.times.map do
            Article.create(title: 'test')
          end
        end

        after { articles.each(&:destroy) }

        it 'returns records' do
          expect(relation.send(:records).map(&:id)).to match_array(articles.map(&:id))
        end
      end

      context 'when records are not present' do
        it 'returns empty array' do
          expect(relation.send(:records)).to eq([])
        end
      end
    end
  end
end
