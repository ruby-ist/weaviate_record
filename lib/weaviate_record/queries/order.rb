# frozen_string_literal: true

module Weaviate
  module Queries
    # This module contains function to sort Weaviate records
    module OrderQuery
      def order(*attributes, **kw_attributes)
        raise ArgumentError, 'expected at least one argument' if attributes.empty? && kw_attributes.empty?

        attributes = combine_attributes(attributes, kw_attributes)
        assign_sort_options(attributes)
        self.loaded = false
        self
      end

      private

      attr_accessor :sort_options

      def combine_attributes(attributes, kw_attributes)
        [*attributes.map! { |attribute| format_sorting_option(attribute) },
         *kw_attributes.map { |attribute, order| format_sorting_option(attribute, order) }]
      end

      def format_sorting_option(attribute, sorting_order = :asc)
        unless attribute.is_a?(Symbol) || attribute.is_a?(String)
          raise TypeError, 'Invalid type for sorting attribute, should be either type or symbol'
        end
        raise Weaviate::Errors::SortingOptionError, 'Invalid sorting order' unless %i[asc desc].include? sorting_order

        if Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key?(attribute.to_s)
          attribute = "_#{Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS[attribute.to_s]}"
        end
        attribute = '_id' if attribute.to_s == 'id'

        "{ path: [#{attribute.to_s.inspect}], order: #{sorting_order} }"
      end

      def assign_sort_options(attributes)
        self.sort_options = if sort_options.present?
                              if sort_options.starts_with?('[')
                                combine_sorting_options(sort_options[2...-2], *attributes)
                              else
                                combine_sorting_options(sort_options, *attributes)
                              end
                            else
                              combine_sorting_options(*attributes)
                            end
      end

      def combine_sorting_options(*sorting_options)
        return sorting_options[0] if sorting_options.size == 1

        "[ #{sorting_options.join(', ')} ]"
      end
    end
  end
end
