# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains functions to perform limit query
    module LimitQuery
      def limit(limit_value)
        raise TypeError, 'Limit should be as integer' unless limit_value.to_i.to_s == limit_value.to_s

        self.limit = limit_value
        self.loaded = false
        self
      end

      private

      attr_writer :limit
    end
  end
end
