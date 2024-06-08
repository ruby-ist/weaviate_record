# frozen_string_literal: true

require 'weaviate'

module WeaviateRecord
  # This module will act as a connection to Weaviate database
  class Connection
    # Returns a _Weaviate::Client_ object, which is used to interact with the Weaviate database.
    attr_reader :client

    # Creates a new Connection to the Weaviate database.
    def initialize(collection_name = nil)
      @collection_name = collection_name&.to_s
      @client = Weaviate::Client.new(
        url: ENV.fetch('WEAVIATE_DATABASE_URL'),
        api_key: ENV.fetch('WEAVIATE_API_KEY', nil),
        model_service: ENV['WEAVIATE_VECTORIZER_MODULE']&.to_sym,
        model_service_api_key: ENV.fetch('WEAVIATE_VECTORIZER_API_KEY', nil)
      )
    end

    # Returns the present schema of the Weaviate database.
    def schema_list
      client.schema.list.deep_symbolize_keys!
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    # :enddoc:

    def find_call(id)
      client.objects.get(class_name: @collection_name, id: id)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    def create_call(properties)
      client.objects.create(class_name: @collection_name, properties: properties)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    def update_call(id, properties)
      client.objects.update(class_name: @collection_name, id: id, properties: properties)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    def delete_call(id)
      client.objects.delete(class_name: @collection_name, id: id)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    def check_existence(id)
      client.objects.exists?(class_name: @collection_name, id: id)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end

    def delete_where(condition)
      client.objects.batch_delete(class_name: @collection_name, where: condition)
    rescue Faraday::ConnectionFailed => e
      raise WeaviateRecord::Errors::DatabaseNotConnected, e.message, cause: nil
    end
  end
end
