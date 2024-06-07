# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # Bm25 is an algorithm to perform keyword based search on collection provided by Weaviate
    # This class contains functions to perform that query
    module Bm25
      # Perform a keyword based search on the collection.
      # You can also optionally pass an array of attributes to search in the collection.
      #
      # ==== Example:
      #   Article.create(content: 'This is a movie about friendship, action and adventure')
      #   # => #<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >
      #
      #   Article.bm25('friendship movie')
      #   # => [#<Article:0x00000001052091e8 id: "983c0970-2c65-4c38-a93f-2ca9272d784b"... >]
      def bm25(text, on_attributes: [])
        text = text.to_str
        return self if text.empty?

        attributes = on_attributes.map(&:to_s)
        @keyword_search = "{ query: #{text.gsub('"', "'").inspect}" \
                          "#{", properties: #{attributes}" if attributes.present?} }"
        @loaded = false
        self
      end
    end
  end
end
