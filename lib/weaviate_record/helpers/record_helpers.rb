# frozen_string_literal: true

module WeaviateRecord
  module Helpers
    # Helper functions for WeaviateRecord class
    module RecordHelpers
      extend ActiveSupport::Concern

      def collection_name
        self.class.to_s
      end

      private

      def update_validation_check(attributes_hash)
        raise ArgumentError, 'update action requires minimum one attribute' if attributes_hash.empty?
        raise Weaviate::Errors::MissingIdError, 'the record doesn\'t have an id' unless additional['id']

        if queried_record
          raise Weaviate::Errors::CustomQueriedRecordError, 'cannot perform update action on custom queried record'
        end

        check_attributes(attributes_hash)
        return unless attributes_hash['_additional'] || attributes_hash[:_additional]

        raise Weaviate::Errors::MetaAttributeError, 'cannot update meta attributes'
      end

      def validate_and_save
        raise Weaviate::Errors::CustomQueriedRecordError, 'cannot modify custom selected record' if queried_record

        return false unless valid?

        result = additional['id'] ? update_call(additional['id'], attributes) : create_call(attributes)
        raise Weaviate::Errors::InternalError, 'unable to save the record on Weaviate' unless result.is_a?(Hash)

        result
      end

      def validate_record_for_destroy
        if queried_record
          raise Weaviate::Errors::CustomQueriedRecordError, 'cannot perform destroy action on custom queried record'
        end

        unless additional['id']
          attributes.each_key { |key| attributes[key] = nil }
          return false
        end
        true
      end

      def run_attribute_handlers(attributes_hash)
        check_attributes(attributes_hash)
        load_attributes(attributes_hash)
        create_attribute_writers
        create_attribute_readers
      end

      class_methods do
        def additional_attributes(record)
          additional = {}
          additional['id'] = record['id']
          additional['created_at'] = DateTime.strptime(record['creationTimeUnix'].to_s, '%Q')
          additional['updated_at'] = DateTime.strptime(record['lastUpdateTimeUnix'].to_s, '%Q')
          additional
        end
      end
    end
  end
end
