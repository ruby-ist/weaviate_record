# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This class contains functions to perform count operation on Weaviate Relations
    module Count
      # Return the count of records matching the given conditions or search filters.
      #
      # +:bm25+ will not work here because it is not supported in aggregation queries
      # +:limit+ and +:offset+ does not work with aggregation queries too
      #
      # ==== Example:
      #     Article.where(title: 'movie').count #=> 1
      def count
        query = to_query.slice(:class_name, :near_text, :near_vector, :near_object, :where)
        query[:fields] = 'meta { count }'
        @connection.client.query.aggs(**query).dig(0, 'meta', 'count')
      end
    end
  end
end
