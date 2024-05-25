# frozen_string_literal: true

require 'weaviate'

module WeaviateRecord
  # This module is used to create a Weaviate connection
  module Connection
    def self.create_client
      @create_client ||= Weaviate::Client.new(
        url: ENV.fetch('WEAVIATE_DATABASE_URL'),
        api_key: ENV.fetch('WEAVIATE_API_KEY', nil),
        model_service: ENV['WEAVIATE_VECTORIZER_MODULE']&.to_sym,
        model_service_api_key: ENV.fetch('WEAVIATE_VECTORIZER_API_KEY', nil)
      )
    end
  end
end
