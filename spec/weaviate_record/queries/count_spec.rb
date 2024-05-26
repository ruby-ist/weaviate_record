# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Count do
  let!(:articles) do
    10.times.map do |i|
      Article.create(content: "content #{i}", title: "Title #{i}",
                     categories: [i.odd? ? 'odd' : 'even'])
    end
  end

  after do
    articles.each(&:destroy)
  end

  it 'returns count in relation' do
    expect(Article.all.count).to eq(10)
  end

  it 'returns count in relation with where conditions' do
    expect(Article.where(categories: ['even']).count).to eq(5)
  end

  it 'does not consider limit or offset' do
    expect(Article.limit(7).offset(1).count).to eq(10)
  end
end
