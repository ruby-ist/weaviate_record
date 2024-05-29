# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module provides method for after query
    module After
      def after(object)
        unless object.instance_of?(@klass) || object.is_a?(String)
          raise TypeError, "Invalid type #{object.class} for object query"
        end

        raise TypeError, 'Invalid uuid' if object.is_a?(String) && !Constants::UUID_REGEX.match?(object)

        @after = object.instance_of?(@klass) ? object.id : object
        @loaded = false
        self
      end
    end
  end
end
