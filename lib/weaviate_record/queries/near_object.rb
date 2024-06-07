# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module includes methods to perform 'near object' queries.
    module NearObject
      # Performs a similarity search based on the given object.
      # This method takes either id of the object or the object itself and returns the list of objects
      # that are nearer to it in terms of vector distance. You can also limit the distance by passing
      # the distance parameter.
      #
      # ==== Example:
      #   Article.create(content: 'This is a movie about friendship, action and adventure')
      #   # => #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >
      #   obj = Article.create(content: 'This is a review about a movie')
      #   # => #<Article:0x00000001052091e8 id: "0476e426-7e7f-4010-bfad-20c57a65c5c7"... >
      #
      #   Article.near_object(obj)
      #   # => [... #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... > ]
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
