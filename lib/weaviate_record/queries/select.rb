module WeaviateRecord
  module Queries
    # This module contains function to perform select query on Weaviate
    module SelectQuery
      def select(*args)
        args.each do |arg|
          if arg.is_a? Hash
            select_options[:nested_attributes].merge! arg
          else
            select_options[:attributes] << arg.to_s unless select_options[:attributes].include?(arg.to_s)
          end
        end
        self.loaded = false
        self
      end

      private

      attr_reader :select_options, :klass

      def combined_fields
        field_names = format_array_element(@select_options[:attributes]) << ' '

        if @select_options[:nested_attributes].present?
          field_names << format_hash_element(@select_options[:nested_attributes])
        end
        field_names.rstrip
      end

      def create_or_process_select_fields(custom, fields)
        if custom
          fields.gsub(/(?<=\s)(#{Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.keys.join('|')})(?=\s)/,
                      Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS)
        else
          properties_list(klass).join(' ') << ' _additional { id creationTimeUnix lastUpdateTimeUnix }'
        end
      end

      def format_array_element(array)
        array.inject('') do |acc, element|
          acc << case element
                 when String, Symbol then "#{element} "
                 when Array then format_array_element(element) << ' '
                 when Hash then format_hash_element(element) << ' ' else raise ArgumentError
                 end
        end.rstrip
      end

      def format_hash_element(hash)
        return_string = ''
        hash.each do |key, value|
          return_string << key.to_s << ' { '
          case value
          when String, Symbol then return_string << value.to_s << ' } '
          when Array then return_string << format_array_element(value) << ' } '
          when Hash then return_string << format_hash_element(value) << ' } ' else raise ArgumentError
          end
        end
        return_string.rstrip
      end
    end
  end
end
