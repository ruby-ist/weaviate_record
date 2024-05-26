# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Connection do
  let(:instance) { described_class.new }

  describe '#client' do
    it 'returns Weavaite::Client object' do
      expect(instance.client).to be_an_instance_of(Weaviate::Client)
    end

    it 'connects with weaviate database' do
      expect(instance.client.url).to eq(ENV.fetch('WEAVIATE_DATABASE_URL', nil))
    end
  end
end
