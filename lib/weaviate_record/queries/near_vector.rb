# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module provides method for after query
    module NearVector
      def near_vector(vector, distance: WeaviateRecord.config.similarity_search_threshold)
        raise TypeError, "Invalid type #{vector.class} for near vector query" unless vector.is_a?(Array)
        raise TypeError, 'Invalid vector' unless vector.all? { |v| v.is_a?(Float) }
        raise TypeError, 'Invalid value for distance' unless distance.is_a?(Numeric)

        @near_vector = "{ vector: #{vector}, distance: #{distance} }"
        @loaded = false
        self
      end
    end
  end
end
