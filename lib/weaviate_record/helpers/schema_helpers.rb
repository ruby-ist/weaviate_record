# frozen_string_literal: true

module WeaviateRecord
  module Helpers
    # Helpers functions that will read the Weaviate 's local schema
    module SchemaHelpers
      private

      def schema_details(klass)
        schema = Weaviate::Structure.current[:classes].find { _1[:class] == klass.to_s }
        raise Weaviate::Errors::CollectionNotFound, "Collection #{klass} not found in the schema" if schema.nil?

        schema
      end

      def properties_list(klass)
        schema_details(klass)[:properties].map { _1[:name] }
      end
    end
  end
end
