# frozen_string_literal: true

module WeaviateRecord
  module Concerns
    # Helpers functions to handle the record attributes mapping
    module AttributeHandlers
      private

      def list_of_valid_attributes
        @list_of_valid_attributes ||= WeaviateRecord::Schema.find_collection(collection_name)
                                                            .attributes_list
      end

      def check_attributes(attributes_hash)
        invalid_attributes = attributes_hash.keys - ['_additional', *list_of_valid_attributes]
        return unless invalid_attributes.present?

        raise WeaviateRecord::Errors::InvalidAttributeError,
              "Invalid attributes #{invalid_attributes} for #{collection_name} record!"
      end

      def merge_attributes(attributes_hash)
        attributes_hash.deep_transform_keys!(&:to_s)
        check_attributes(attributes_hash)
        attributes_hash.each do |key, value|
          @attributes[key] = value
        end
      end

      def load_attributes(attributes_hash)
        if attributes_hash.empty? || !@custom_selected
          list_of_valid_attributes.each do |attribute|
            @attributes[attribute] = nil
          end
        end

        attributes_hash.each do |key, value|
          next if key == '_additional'

          @attributes[key] = value
        end
      end

      def create_attribute_writers
        list_of_valid_attributes.each do |name|
          define_singleton_method("#{name}=") do |value|
            @attributes[name] = value
          end
        end
      end

      def create_attribute_readers
        attributes_list = @custom_selected ? @attributes.each_key : list_of_valid_attributes
        attributes_list.each do |name|
          define_singleton_method(name) { @attributes[name] }
        end

        handle_timestamp_attributes
        @meta_attributes.each_key do |name|
          define_singleton_method(name.underscore) { @meta_attributes[name] }
        end
      end

      def handle_timestamp_attributes
        replace_timestamp_attribute('creationTimeUnix') if @meta_attributes.key? 'creationTimeUnix'
        replace_timestamp_attribute('lastUpdateTimeUnix') if @meta_attributes.key? 'lastUpdateTimeUnix'
      end

      def replace_timestamp_attribute(attribute)
        mapped_attribute = WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key(attribute)
        @meta_attributes[mapped_attribute] = if @meta_attributes[attribute]
                                               DateTime.strptime(@meta_attributes[attribute], '%Q')
                                             end
        @meta_attributes.delete(attribute)
      end
    end
  end
end
