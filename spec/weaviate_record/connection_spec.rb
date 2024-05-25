# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Connection do
  describe '#create_client' do
    it 'returns Weavaite::Client object' do
      expect(described_class.create_client).to be_an_instance_of(Weaviate::Client)
    end

    it 'connects with weaviate database' do
      expect(described_class.create_client.url).to eq(ENV.fetch('WEAVIATE_DATABASE_URL', nil))
    end
  end
end
