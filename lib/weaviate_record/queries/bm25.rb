# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # Bm25 is an algorithm to perform keyword based search on collection provided by Weaviate
    # This class contains functions to perform that query
    module Bm25
      def bm25(text, on_attributes: [])
        text = text.to_str
        raise WeaviateRecord::Errors::EmptyPrompt, 'text cannot be empty' if text.empty?

        attributes = on_attributes.map(&:to_s)
        @keyword_search = "{ query: #{text.gsub('"', "'").inspect}" \
                          "#{", properties: #{attributes}" if attributes.present?} }"
        @loaded = false
        self
      end
    end
  end
end
