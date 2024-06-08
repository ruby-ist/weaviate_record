# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Relation::QueryBuilder do
  describe '#to_query' do
    let(:article) { WeaviateRecord::Relation.new(Article) }
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
      relation.where(title: 'article')
      expect(relation.to_query).to have_key(:where)
    end
  end
end
