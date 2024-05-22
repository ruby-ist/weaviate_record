# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This class contains functions to perform count operation on Weaviate Relations
    module Count
      def count
        # :bm25 is not included here because it is not supported in aggregation queries
        # :limit and :offset does not work with aggregation queries too
        query = to_query.slice(:class_name, :near_text, :where)
        query[:fields] = 'meta { count }'
        WeaviateRecord::Connection.new.query.aggs(**query).dig(0, 'meta', 'count')
      end
    end
  end
end
