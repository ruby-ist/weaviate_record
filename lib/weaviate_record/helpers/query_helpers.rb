# frozen_string_literal: true

module Weaviate
  class Record
    # Helper functions to make query calls from record to Weavaite
    module QueryHandlers
      extend ActiveSupport::Concern

      private

      attr_reader :client

      def create_call(properties)
        client.objects.create(class_name: collection_name, properties:)
      end

      def update_call(id, properties)
        client.objects.update(class_name: collection_name, id:, properties:)
      end

      def delete_call(id)
        client.objects.delete(class_name: collection_name, id:)
      end

      class_methods do
        def find_call(id)
          client = Weaviate::Connection.create_client
          client.objects.get(class_name: to_s, id:)
        end
      end
    end
  end
end
