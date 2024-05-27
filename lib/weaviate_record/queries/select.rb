# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to perform select query on Weaviate
    module Select
      def select(*args)
        args.each do |arg|
          if arg.is_a? Hash
            @select_options[:nested_attributes].merge! arg
          else
            @select_options[:attributes] << arg.to_s unless @select_options[:attributes].include?(arg.to_s)
          end
        end
        @loaded = false
        self
      end

      private

      def combined_select_attributes
        attributes = format_array_attribute(@select_options[:attributes])
        return attributes if @select_options[:nested_attributes].empty?

        "#{attributes} #{format_nested_attribute(@select_options[:nested_attributes])}"
      end

      def create_or_process_select_attributes(custom_selected, attributes)
        if custom_selected
          attributes.gsub(/(?<=\s)(#{WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.keys.join('|')})(?=\s)/,
                          WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS)
        else
          [
            *WeaviateRecord::Schema.find_collection(@klass).attributes_list,
            '_additional { id creationTimeUnix lastUpdateTimeUnix }'
          ].join(' ')
        end
      end

      def format_array_attribute(array)
        array.map do |attribute|
          case attribute
          when String, Symbol then attribute.to_s
          when Array then format_array_attribute(attribute)
          when Hash then format_nested_attribute(attribute)
          else raise TypeError
          end
        end.join(' ')
      end

      def format_nested_attribute(hash)
        return_string = String.new
        hash.each do |key, value|
          return_string << key.to_s << ' { '
          case value
          when String, Symbol then return_string << value.to_s << ' } '
          when Array then return_string << format_array_attribute(value) << ' } '
          when Hash then return_string << format_nested_attribute(value) << ' } ' else raise TypeError
          end
        end
        return_string.rstrip
      end
    end
  end
end
