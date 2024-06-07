# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to perform select query on Weaviate
    module Select
      # Select the attributes to be fetched from the database.
      # You can also pass nested attributes to be fetched.
      # Meta attributes that needs to be fetched should be passed aa a value for key '_additional'.
      # In Weaviate, +id+ is also a meta attribute.
      # If select is not called on a Weaviate query, by default
      # it will fetch all normak attributes with id and timestamps.
      #
      # ==== Example:
      #   Article.select(:content, :title)
      #   Article.select(_additional: :vector)
      #   Article.select( _additional: [:id, :created_at, :updated_at])
      #   Article.select(_additional: { answer: :result })
      #
      #   Article.all #=> fetches id, content, title, created_at, updated_at
      #
      # There is one more special scenario where you can pass the graphql query directly.
      # It will be used for summarization offered by summarizer module.
      #
      # ==== Example:
      #   Article.select(_additional: 'summary(properties: ["content"]) { result }')
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
