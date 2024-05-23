# frozen_string_literal: true

module WeaviateRecord
  # Inspect definition for Weaviate Record
  module Inspect
    def inspect
      special_attributes, inspection = format_attributes
      string = to_s
      string[-1] = ' '
      string << "id: #{special_attributes['id'].inspect} " << inspection
      string << " created_at: #{special_attributes['created_at'].inspect}" if special_attributes.key? 'created_at'
      string << " updated_at: #{special_attributes['updated_at'].inspect}" if special_attributes.key? 'updated_at'
      string << '>'
    end

    private

    def format_attributes
      attributes_list = { **additional, **attributes }
      special_attributes = attributes_list.slice('id', 'created_at', 'updated_at')
      attributes_list.except!(*special_attributes.keys)
      inspection = attributes_list.sort.map do |key, value|
        format_for_inspect(key, value)
      end.join(', ')
      [special_attributes, inspection]
    end

    def format_for_inspect(key, value)
      formatted_value = case value
                        when String then value.truncate(25).inspect
                        when Array then key == 'vector' ? "[#{value.first(4).join(', ')}...]" : value.inspect
                        else value.inspect
                        end
      "#{key.underscore}: #{formatted_value}"
    end
  end
end
