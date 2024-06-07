# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module provides method for near vector query
    module NearVector
      # Performs a similarity search based on the given vector.
      # This method takes a vector (Array of float values) and
      # returns the list of objects that are nearer to it in terms of vector distance.
      # You can also limit the distance by passing the distance parameter.
      #
      # ==== Example:
      #  Article.create(content: 'This is a movie about friendship, action and adventure')
      #  # => #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >
      #
      #  vector = Article.select(_additional: :vector).where(id: "983c0970-2c65-4c38-a93f-2ca9272d784b").vector
      #  # => [-0.37226558, 0.10700592, -0.3906307, 0.1064298 ... ]
      #
      #  Article.near_vector(vector)
      #  # => [... #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... > ]
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
