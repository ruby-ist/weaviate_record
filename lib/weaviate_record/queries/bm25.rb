# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # Bm25 is an algorithm to perform keyword based search on collection provided by Weaviate
    # This class contains functions to perform that query
    module Bm25
      def bm25(text)
        raise TypeError, 'text must be a string' unless text.is_a?(String)

        self.keyword_search = text if text.present?
        self.loaded = false
        self
      end

      private

      attr_writer :keyword_search
    end
  end
end
