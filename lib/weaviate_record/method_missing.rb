# frozen_string_literal: true

module WeaviateRecord
  # Method missing definition for Weaviate Record
  module MethodMissing
    private

    def list_of_attributes
      [*properties_list(collection_name), *WeaviateRecord::Constants::META_ATTRIBUTES]
    end

    def method_missing(name, *args)
      method = name.to_s
      if list_of_attributes.include? method
        raise WeaviateRecord::Errors::MissingAttributeError, "missing attribute: #{method}"
      end

      super
    end

    def respond_to_missing?(*_args)
      list_of_attributes.include?(method) ? true : super
    end
  end
end
