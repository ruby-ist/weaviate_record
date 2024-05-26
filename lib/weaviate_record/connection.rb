# frozen_string_literal: true

require 'weaviate'

module WeaviateRecord
  # This module will act as a connection to Weaviate database
  class Connection
    attr_reader :client, :collection_name

    def initialize(collection_name = nil)
      @collection_name = collection_name
      @client = Weaviate::Client.new(
        url: ENV.fetch('WEAVIATE_DATABASE_URL'),
        api_key: ENV.fetch('WEAVIATE_API_KEY', nil),
        model_service: ENV['WEAVIATE_VECTORIZER_MODULE']&.to_sym,
        model_service_api_key: ENV.fetch('WEAVIATE_VECTORIZER_API_KEY', nil)
      )
    end

    def find_call(id)
      client.objects.get(class_name: collection_name, id: id)
    end

    def create_call(properties)
      client.objects.create(class_name: collection_name, properties: properties)
    end

    def update_call(id, properties)
      client.objects.update(class_name: collection_name, id: id, properties: properties)
    end

    def delete_call(id)
      client.objects.delete(class_name: collection_name, id: id)
    end
  end
end
