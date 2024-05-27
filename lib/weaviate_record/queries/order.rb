# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to sort Weaviate records
    module Order
      def order(*args, **kw_args)
        raise ArgumentError, 'expected at least one argument' if args.empty? && kw_args.empty?

        sorting_specifiers = combine_arguments(args, kw_args)
        assign_sort_options(sorting_specifiers)
        @loaded = false
        self
      end

      private

      def validate_attribute_and_order(attribute, sorting_order)
        unless attribute.is_a?(Symbol) || attribute.is_a?(String)
          raise TypeError, 'Invalid type for sorting attribute, should be either type or symbol'
        end

        return if %i[asc desc].include? sorting_order

        raise WeaviateRecord::Errors::SortingOptionError, 'Invalid sorting order'
      end

      def combine_arguments(args, kw_args)
        [*args.map! { |attribute| convert_to_sorting_specifier(attribute) },
         *kw_args.map { |attribute, sorting_order| convert_to_sorting_specifier(attribute, sorting_order) }]
      end

      def convert_to_sorting_specifier(attribute, sorting_order = :asc)
        validate_attribute_and_order(attribute, sorting_order)
        attribute = map_to_weaviate_attribute(attribute)

        "{ path: [#{attribute.to_s.inspect}], order: #{sorting_order} }"
      end

      def map_to_weaviate_attribute(attribute)
        return '_id' if attribute.to_s == 'id'
        return attribute unless WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key?(attribute.to_s)

        "_#{WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS[attribute.to_s]}"
      end

      def assign_sort_options(sorting_specifiers)
        @sort_options = if @sort_options.nil?
                          merge_sorting_specifiers(*sorting_specifiers)
                        elsif @sort_options.start_with?('[')
                          merge_sorting_specifiers(@sort_options[2...-2], *sorting_specifiers)
                        else
                          merge_sorting_specifiers(@sort_options, *sorting_specifiers)
                        end
      end

      def merge_sorting_specifiers(*sorting_specifiers)
        return sorting_specifiers[0] if sorting_specifiers.size == 1

        "[ #{sorting_specifiers.join(', ')} ]"
      end
    end
  end
end
