# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains functions to perform limit query
    module Limit
      def limit(limit_value)
        raise TypeError, 'Limit should be as integer' unless limit_value.to_i.to_s == limit_value.to_s

        @limit = limit_value
        @loaded = false
        self
      end
    end
  end
end
