# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains functions to perform near_text query (Context Based Search)
    module NearText
      # Perform a similarity search on Weaviate collection.
      # This method also takes an optional distance parameter to specify the threshold of similarity.
      # You can also pass multiple texts to search in the collection.
      #
      # ==== Example:
      #   Article.create(content: 'This is a movie about friendship, action and adventure')
      #   # => #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >
      #
      #   Article.near_text('review about a movie')
      #   # => [#<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >]
      def near_text(*texts, distance: WeaviateRecord.config.similarity_search_threshold)
        raise TypeError, 'invalid value for text' unless texts.all? { |text| text.is_a?(String) }
        raise TypeError, 'Invalid value for distance' unless distance.is_a?(Numeric)

        @near_text_options[:distance] = distance
        @near_text_options[:concepts] += texts.map! { |text| text.gsub('"', "'") }
        @loaded = false
        self
      end

      private

      def formatted_near_text_value
        texts = @near_text_options[:concepts].map(&:inspect).join(', ')

        "{ concepts: [#{texts}], distance: #{@near_text_options[:distance]} }"
      end
    end
  end
end
