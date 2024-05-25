# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe WeaviateRecord::Schema do
  describe '.all_collection' do
    # context 'when a class is present in the schema' do
    #   it 'returns the schema details of a class' do
    #     expect(instance.send(:schema_details, 'DocumentTest').keys).to match_array(%i[class
    #                                                                                   description
    #                                                                                   invertedIndexConfig
    #                                                                                   moduleConfig
    #                                                                                   multiTenancyConfig
    #                                                                                   properties
    #                                                                                   replicationConfig
    #                                                                                   shardingConfig
    #                                                                                   vectorIndexConfig
    #                                                                                   vectorIndexType
    #                                                                                   vectorizer])
    #   end
    # end

    context 'when a class is not present in the schema' do
      it 'raises CollectionNotFound error' do
        expect do
          described_class.find_collection('NonExistingClass')
        end.to raise_error(WeaviateRecord::Errors::CollectionNotFound,
                           'Collection NonExistingClass not found in the schema')
      end
    end
  end

  describe '#attributes_list' do
    it 'returns the list of attributes of a collection class' do
      schema = described_class.send(:new, { properties: [{ name: 'title' }, { name: 'content' },
                                                         { name: 'type' }, { name: 'tags' }] })
      expect(schema.attributes_list).to match_array(%w[title content type tags])
    end
  end

  describe '#update!' do
    before do
      allow(File).to receive(:write)
    end

    let(:schema) { WeaviateRecord::Connection.create_client.schema.list.deep_symbolize_keys! }

    it 'writes the db/weaviate/schema.rb file' do
      described_class.update!
      expect(File).to have_received(:write).with(
        WeaviateRecord.config.schema_file_path,
        WeaviateRecord::Schema.singleton_class::STRUCTURE_FILE_BOILERPLATE[schema.pretty_inspect]
      )
    end

    it 'updates the Weaviate Structure' do
      described_class.update!
      current_schema = described_class.all_collections
      weaviate_schema = WeaviateRecord::Connection.create_client.schema.list.deep_symbolize_keys!
      expect(current_schema).to eq(weaviate_schema)
    end
  end
end
