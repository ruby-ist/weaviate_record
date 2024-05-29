# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module includes methods to perform 'near object' queries.
    module NearObject
      def near_object(object, distance: WeaviateRecord.config.similarity_search_threshold)
        unless object.is_a?(WeaviateRecord::Base) || object.is_a?(String)
          raise TypeError, "Invalid type #{object.class} for near object query"
        end

        raise TypeError, 'Invalid uuid' if object.is_a?(String) && !Constants::UUID_REGEX.match?(object)
        raise TypeError, 'Invalid value for distance' unless distance.is_a?(Numeric)

        @near_object = "{ id: #{(object.is_a?(WeaviateRecord::Base) ? object.id : object).inspect}, " \
                       "distance: #{distance} }"
        @loaded = false
        self
      end
    end
  end
end
