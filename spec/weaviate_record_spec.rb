# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord do
  describe '.config' do
    it 'responds to similarity_search_threshold' do
      expect(described_class.config).to respond_to(:similarity_search_threshold)
    end

    it 'responds to similarity_search_threshold=' do
      expect(described_class.config).to respond_to(:similarity_search_threshold=)
    end

    it 'responds to schema_file_path' do
      expect(described_class.config).to respond_to(:schema_file_path)
    end

    it 'responds to schema_file_path=' do
      expect(described_class.config).to respond_to(:schema_file_path=)
    end

    it 'sets default similarity_search_threshold to 0.55' do
      expect(described_class.config.similarity_search_threshold).to be(0.55)
    end

    it 'sets default schema_file_path to db/weaviate/schema.rb' do
      expect(described_class.config.schema_file_path).to eql("#{Dir.pwd}/db/weaviate/schema.rb")
    end

    context 'with Rails application' do
      before do
        stub_const('Rails', class_double('Rails')) unless Object.const_defined?('Rails')
        allow(Rails).to receive(:root).and_return('/rails/root')
        described_class.instance_variable_set(:@config, nil)
      end

      it 'sets default schema_file_path to Rails.root/db/weaviate/schema.rb' do
        expect(described_class.config.schema_file_path).to eql('/rails/root/db/weaviate/schema.rb')
      end
    end
  end

  describe '.configure' do
    it 'accepts block and yield config struct' do
      described_class.configure do |config|
        config.similarity_search_threshold = 0.6
      end

      expect(described_class.config.similarity_search_threshold).to be(0.6)
    end

    it 'syncs schema if sync_schema_on_load is true' do
      allow(WeaviateRecord::Schema).to receive(:synced?).and_return(false)
      expect(WeaviateRecord::Schema).to receive(:update!)

      described_class.configure do |config|
        config.sync_schema_on_load = true
      end
    end
  end
end
