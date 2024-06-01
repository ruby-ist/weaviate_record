# frozen_string_literal: true

module WeaviateRecord
  module MethodMissing # :nodoc:
    private

    def list_of_all_attributes
      [*WeaviateRecord::Schema.find_collection(collection_name).attributes_list,
       *WeaviateRecord::Constants::META_ATTRIBUTES]
    end

    def method_missing(method, *args, &block)
      if list_of_all_attributes.include? method.to_s
        raise WeaviateRecord::Errors::MissingAttributeError, "missing attribute: #{method}"
      end

      super
    end

    def respond_to_missing?(method, include_all = false)
      list_of_all_attributes.include?(method.to_s) ? true : super
    end
  end
end
