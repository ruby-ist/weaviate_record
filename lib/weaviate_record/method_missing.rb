# frozen_string_literal: true

module WeaviateRecord
  # Method missing definition for Weaviate Record
  module MethodMissing
    private

    def method_missing(name, *args)
      method = name.to_s
      if [*properties_list(collection_name), *Weaviate::Constants::META_ATTRIBUTES].include? method
        raise Weaviate::Errors::MissingAttributeError, "missing attribute: #{method}"
      end

      super
    end

    def respond_to_missing?(*_args)
      super
    end
  end
end
