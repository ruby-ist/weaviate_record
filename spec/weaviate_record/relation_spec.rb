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
                                                                           .near_text_default_distance })
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

  describe '#inspect' do
    let(:relation) { described_class.new(Article) }

    describe '#records' do
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

    it 'has alias method :all' do
      expect(relation.method(:inspect)).to eq(relation.method(:all))
    end

    it 'has alias method :to_a' do
      expect(relation.method(:inspect)).to eq(relation.method(:to_a))
    end
  end

  describe '#to_query' do
    let(:article) { described_class.new(Article) }
    let(:relation) { article.select(:type, :content).limit(1).offset(2) }

    it 'returns query format' do
      expected_query = { class_name: 'Article', fields: 'type content',
                         limit: '1', offset: '2' }
      expect(relation.to_query).to eq(expected_query)
    end

    it 'adds near_text field optionally' do
      relation.near_text('lead got banned')
      expect(relation.to_query).to have_key(:near_text)
    end

    it 'adds bm25 field optionally' do
      relation.bm25('banned lead')
      expect(relation.to_query).to have_key(:bm25)
    end

    it 'adds where field optionally' do
      relation.where(type: 'article')
      expect(relation.to_query).to have_key(:where)
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
