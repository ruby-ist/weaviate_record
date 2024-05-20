# frozen_string_literal: true

module Weaviate
  class Record
    # Helpers functions to handle the record attributes mapping
    module AttributeHandlers
      private

      def check_attributes(attributes_hash)
        invalid_fields = attributes_hash.keys - ['_additional', *properties_list(collection_name)]
        return unless invalid_fields.present?

        raise Weaviate::Errors::InvalidAttributeError,
              "Invalid attributes #{invalid_fields} for #{collection_name} record!"
      end

      def merge_attributes(attributes_hash)
        attributes_hash.transform_keys!(&:to_s)
        check_attributes(attributes_hash)
        attributes_hash.each do |key, value|
          attributes[key] = value
        end
      end

      def load_attributes(attributes_hash)
        if attributes_hash.empty? || !queried_record
          properties_list(collection_name).each do |attribute|
            attributes[attribute] = nil
          end
        end

        attributes_hash.each do |key, value|
          next if key == '_additional'

          attributes[key] = value
        end
      end

      def create_attribute_writers
        all_attributes = properties_list(collection_name)

        all_attributes.each do |name|
          define_singleton_method("#{name}=") do |value|
            attributes[name] = value
          end
        end
      end

      def create_attribute_readers
        attributes_list = queried_record ? attributes.keys : properties_list(collection_name)
        attributes_list.each do |name|
          define_singleton_method(name) { attributes[name] }
        end

        handle_timestamp_attributes
        additional.each_key do |name|
          define_singleton_method(name.underscore) { additional[name] }
        end
      end

      def handle_timestamp_attributes
        replace_timestamp_attribute('creationTimeUnix') if additional.key? 'creationTimeUnix'
        replace_timestamp_attribute('lastUpdateTimeUnix') if additional.key? 'lastUpdateTimeUnix'
      end

      def replace_timestamp_attribute(attribute)
        mapped_attribute = Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key(attribute)
        additional[mapped_attribute] = additional[attribute] ? DateTime.strptime(additional[attribute], '%Q') : nil
        additional.delete(attribute)
      end
    end
  end
end
