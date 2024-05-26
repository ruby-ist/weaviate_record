# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Where do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Where
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  before do
    described_class.private_instance_methods.each do |method|
      allow(instance).to receive(method).with(any_args).and_call_original
    end
  end

  describe '#where' do
    it 'raises an error when no arguments are passed' do
      expect do
        instance.where
      end.to raise_error(WeaviateRecord::Errors::InvalidWhereQueryError, 'invalid argument for where query')
    end

    it 'raises an error when the number of arguments does not match the number of placeholders' do
      expect do
        instance.where('author = ?', 'nobody', 'test')
      end.to raise_error(WeaviateRecord::Errors::InvalidWhereQueryError, 'invalid number of arguments')
    end

    it 'sets loaded to false' do
      instance.where('title = ?', 'test')
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.where('title = ?', 'test')).to eq(instance)
    end

    it 'calls process_keyword_conditions' do
      instance.where(title: 'test')
      expect(instance).to have_received(:process_keyword_conditions).with({ title: 'test' })
    end

    it 'calls process_string_conditions' do
      instance.where('title = ?', 'test')
      expect(instance).to have_received(:process_string_conditions).with('title = ?', 'test')
    end

    it 'calls combine_queries' do
      instance.where('content = ?', 'article', title: 'test')
      expect(instance).to have_received(:combine_queries).with(
        '{ path: ["title"], operator: Equal, valueText: "test" }',
        '{ path: ["content"], operator: Equal, valueText: "article" }'
      )
    end

    context 'when where_query is nil' do
      before do
        instance.instance_variable_set(:@where_query, nil)
      end

      it 'sets where_query to the combined query' do
        instance.where('content = ?', 'article', title: 'test')
        expect(instance.instance_variable_get(:@where_query)).not_to be_nil
      end
    end

    context 'when where_query is present' do
      before do
        allow(instance).to receive(:create_logical_condition)
      end

      it 'calls create_logical_condition with existing where_query and new query' do
        instance.instance_variable_set(:@where_query, '{ path: ["content"], operator: Equal, valueText: "article" }')
        instance.where(title: 'test')
        expect(instance).to have_received(:create_logical_condition)
      end
    end

    context 'with Queries' do
      let!(:articles) do
        6.times.map do |index|
          Article.create(title: "article #{index}", author: "author #{index & 1}")
        end
      end

      after { articles.each(&:destroy) }

      it 'can take conditions as string' do
        expect(Article.where('title = ?', 'article 1').first.id).to eq(articles[1].id)
      end

      it 'can take conditions with keyword' do
        expect(Article.where(title: 'article 2').first.id).to eq(articles[2].id)
      end

      it 'can take multiple conditions' do
        expect(Article.where('author = ? OR title LIKE ?', 'author 0', 'article 1').count).to be(4)
      end

      it 'can take chained conditions' do
        expect(Article.where(author: 'author 1').where('title LIKE ?', 'article 1').first.id)
          .to eq(articles[1].id)
      end

      it 'can take conditions with meta attributes' do
        expect(Article.where('created_at > ?', Date.yesterday).count).to eq(6)
      end
    end
  end

  describe '#process_keyword_conditions' do
    context 'when hash is empty' do
      it 'returns nil when hash is empty' do
        expect(instance.send(:process_keyword_conditions, {})).to be_nil
      end
    end

    context 'when hash is not empty' do
      it 'calls #create_query_condition for each key-value pair with = operator' do
        instance.send(:process_keyword_conditions, content: 'article', title: 'test')
        [%w[content = article], %w[title = test]].each do |equation|
          expect(instance).to have_received(:create_query_condition).with(equation)
        end
      end

      it 'combines conditions with logical AND operator' do
        kw_args = { title: 'test', content: 'this is test' }
        instance.send(:process_keyword_conditions, **kw_args)
        expect(instance).to have_received(:create_logical_condition).with(any_args).exactly(kw_args.size - 1).times
      end
    end
  end

  describe '#process_string_conditions' do
    context 'when query is empty' do
      it 'returns nil' do
        expect(instance.send(:process_string_conditions, '')).to be_nil
      end
    end

    context 'when query is not empty' do
      context 'when query does not contain logical operators' do
        it 'returns formatted where condition' do
          expect(instance.send(:process_string_conditions, 'title = ?', 'test'))
            .to eq('{ path: ["title"], operator: Equal, valueText: "test" }')
        end
      end

      context 'when query contains logical operators' do
        it 'returns formatted logical where condition' do
          expect(instance.send(:process_string_conditions, 'content = ? AND title = ?', 'test', 'title'))
            .to eq('{ operator: And, operands: [' \
                   '{ path: ["content"], operator: Equal, valueText: "test" }, ' \
                   '{ path: ["title"], operator: Equal, valueText: "title" }] }')
        end

        it 'calls itself with post_match' do
          allow(instance).to receive(:process_string_conditions).with('content = ? AND title = ?',
                                                                      'test', 'title').and_call_original
          instance.send(:process_string_conditions, 'content = ? AND title = ?', 'test', 'title')
          expect(instance).to have_received(:process_string_conditions).with('title = ?', 'title')
        end

        context 'when logical operator is OR' do
          it 'combines conditions with logical operator in the query' do
            pre_condition = instance.send(:create_query_condition_from_string, 'content = ?', ['test'])
            post_condition = instance.send(:create_query_condition_from_string, 'title = ?', ['title'])
            instance.send(:process_string_conditions, 'content = ? OR title = ?', 'test', 'title')
            expect(instance).to have_received(:create_logical_condition).with(pre_condition, 'OR',
                                                                              post_condition)
          end
        end

        context 'when logical operator is AND' do
          it 'combines conditions with logical operator in the query' do
            pre_condition = instance.send(:create_query_condition_from_string, 'content = ?', ['test'])
            post_condition = instance.send(:create_query_condition_from_string, 'title = ?', ['title'])
            instance.send(:process_string_conditions, 'content = ? AND title = ?', 'test', 'title')
            expect(instance).to have_received(:create_logical_condition).with(pre_condition, 'AND',
                                                                              post_condition)
          end
        end
      end
    end
  end

  describe '#create_query_condition_from_string' do
    context 'when equation size is not 3' do
      it 'raises an error' do
        expect do
          instance.send(:create_query_condition_from_string, 'content =', ['article'])
        end.to raise_error(WeaviateRecord::Errors::InvalidWhereQueryError, 'unable to process the query')
      end
    end

    context 'when values are empty' do
      it 'raises an error' do
        expect do
          instance.send(:create_query_condition_from_string, 'content = ?', [])
        end.to raise_error(WeaviateRecord::Errors::InvalidWhereQueryError, 'insufficient values for formatting')
      end
    end

    it 'returns a formatted condition' do
      expect(instance.send(:create_query_condition_from_string, 'content = ?',
                           ['article'])).to eq('{ path: ["content"], operator: Equal, valueText: "article" }')
    end

    it 'removes the first value from the array' do
      values = %w[article test]
      instance.send(:create_query_condition_from_string, 'content = ?', values)
      expect(values).to eq(['test'])
    end

    it 'calls #create_query_condition with condition as an array' do
      instance.send(:create_query_condition_from_string, 'content = ?', ['article'])
      expect(instance).to have_received(:create_query_condition).with(%w[content = article])
    end
  end

  describe '#combine_queries' do
    context 'when both queries are present' do
      it 'calls #create_logical_condition with both queries' do
        instance.send(:combine_queries, 'query_1', 'query_2')
        expect(instance).to have_received(:create_logical_condition).with('query_1', 'And', 'query_2')
      end
    end

    context 'when one of the queries is nil' do
      it 'returns the present query' do
        [['query', nil], [nil, 'query']].each do |queries|
          expect(instance.send(:combine_queries, *queries)).to eq('query')
        end
      end
    end
  end

  describe '#create_query_condition' do
    context 'when value is nil' do
      it 'calls #null_condition with attribute' do
        instance.send(:create_query_condition, %w[content =])
        expect(instance).to have_received(:null_condition).with('content')
      end
    end

    context 'when value is not nil' do
      it 'calls #handle_timestamps_condition' do
        instance.send(:create_query_condition, %w[created_at = 2020-01-01])
        expect(instance).to have_received(:handle_timestamps_condition)
      end

      it 'calls #map_operator with operator' do
        instance.send(:create_query_condition, %w[created_at >= 2024-01-01])
        expect(instance).to have_received(:map_operator).with('>=')
      end

      it 'calls #map_value_type with value' do
        instance.send(:create_query_condition, %w[content = articles])
        expect(instance).to have_received(:map_value_type).with('articles')
      end

      it 'returns a formatted condition' do
        expect(instance.send(:create_query_condition,
                             %w[content = article])).to eq('{ path: ["content"], operator: Equal, valueText: "article" }')
      end
    end
  end

  describe '#handle_timestamps_condition' do
    context 'when attribute is not created_at or updated_at' do
      it 'returns nil' do
        expect(instance.send(:handle_timestamps_condition, %w[content = article])).to be_nil
      end
    end

    context 'when attribute is created_at or updated_at' do
      context 'when the attribute is created_at' do
        it 'map the attribute with _creationTimeUnix' do
          condition = %w[created_at = 2020-01-01]
          instance.send(:handle_timestamps_condition, condition)
          expect(condition[0]).to eq("_#{WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS['created_at']}")
        end
      end

      context 'when the attribute is updated_at' do
        it 'map the attribute with _lastUpdateTimeUnix' do
          condition = %w[updated_at = 2020-01-01]
          instance.send(:handle_timestamps_condition, condition)
          expect(condition[0]).to eq("_#{WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS['updated_at']}")
        end
      end

      it 'converts the date to unix equivalent' do
        condition = %w[created_at = 2020-01-01]
        instance.send(:handle_timestamps_condition, condition)
        expect(condition[2]).to eq('1577836800000')
      end
    end
  end

  describe '#null_condition' do
    it 'returns a null condition for attribute' do
      expect(instance.send(:null_condition, 'content')).to eq('{ path: ["content"], operator: IsNull, valueBoolean: true }')
    end
  end

  describe '#form_logical_condition' do
    it 'returns a logical condition expected by Weaviate' do
      expect(instance.send(:create_logical_condition, 'query_1', 'AND',
                           'query_2')).to eq('{ operator: And, operands: [query_1, query_2] }')
    end
  end

  describe '#map_operator' do
    it 'raise Error if the operator not in OPERATOR_MAPPING_HASH' do
      expect do
        instance.send(:map_operator, 'BETWEEN')
      end.to raise_error(WeaviateRecord::Errors::InvalidOperatorError, 'Invalid conditional operator BETWEEN')
    end

    it 'returns the operator from OPERATOR_MAPPING_HASH' do
      expect(instance.send(:map_operator, '!=')).to eq('NotEqual')
    end
  end

  describe '#map_value_type' do
    it 'raise Error if the value type not in TYPE_MAPPING_HASH' do
      expect do
        instance.send(:map_value_type, nil)
      end.to raise_error(WeaviateRecord::Errors::InvalidValueTypeError, 'Invalid value type NilClass for comparison')
    end

    it 'returns the value type from TYPE_MAPPING_HASH' do
      expect(instance.send(:map_value_type, 'articles')).to eq('valueText')
    end
  end
end
