# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to offset Weaviate records
    module Offset
      def offset(offset_value)
        raise TypeError, 'Offset should be an integer' unless offset_value.to_i.to_s == offset_value.to_s

        self.offset = offset_value
        self.loaded = false
        self
      end

      private

      attr_writer :offset
    end
  end
end
