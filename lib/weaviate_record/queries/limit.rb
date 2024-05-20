# frozen_string_literal: true

module Weaviate
  module Queries
    # This module contains functions to perform limit query
    module LimitQuery
      attr_writer :limit
      private :limit=

      def limit(limit_value)
        raise TypeError, 'Limit should be a number' unless limit_value.to_i.to_s == limit_value.to_s

        self.limit = limit_value
        self.loaded = false
        self
      end
    end
  end
end
