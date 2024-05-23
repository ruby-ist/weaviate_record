# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Count do
  # let!(:documents) do
  #   10.times.map do |i|
  #     DocumentTest.create(type: 'article', content: "content #{i}", title: "Title #{i}",
  #                         tags: [i.odd? ? 'odd' : 'even'])
  #   end
  # end

  # after(:each) do
  #   documents.each(&:destroy)
  # end

  # it 'returns count in relation' do
  #   expect(DocumentTest.all.count).to eq(10)
  # end

  # it 'returns count in relation with where conditions' do
  #   expect(DocumentTest.where(tags: ['even']).count).to eq(5)
  # end

  # it 'does not consider limit or offset' do
  #   expect(DocumentTest.limit(7).offset(1).count).to eq(10)
  # end
end
