# frozen_string_literal: true

module Weaviate
  module Queries
    # This module contains function to offset Weaviate records
    module OffsetQuery
      attr_writer :offset
      private :offset=

      def offset(offset_value)
        raise TypeError, 'Offset should be a number' unless offset_value.to_i.to_s == offset_value.to_s

        self.offset = offset_value
        self.loaded = false
        self
      end
    end
  end
end
