# frozen_string_literal: true

module WeaviateRecord
  module Concerns
    # Helper functions for WeaviateRecord class
    module RecordConcern
      extend ActiveSupport::Concern
      include AttributeConcern

      def collection_name
        self.class.to_s
      end

      private

      def run_attribute_handlers(attributes_hash)
        check_attributes(attributes_hash)
        load_attributes(attributes_hash)
        create_attribute_writers
        create_attribute_readers
      end

      def validate_record_for_update(attributes_hash)
        raise ArgumentError, 'update action requires minimum one attribute' if attributes_hash.empty?
        raise WeaviateRecord::Errors::MissingIdError, 'the record doesn\'t have an id' unless @meta_attributes['id']

        if @custom_selected
          raise WeaviateRecord::Errors::CustomQueriedRecordError,
                'cannot perform update action on custom selected record'
        end

        check_attributes(attributes_hash)
        return unless attributes_hash['_additional'] || attributes_hash[:_additional]

        raise WeaviateRecord::Errors::MetaAttributeError, 'cannot update meta attributes'
      end

      def validate_and_save
        if @custom_selected
          raise WeaviateRecord::Errors::CustomQueriedRecordError, 'cannot modify custom selected record'
        end
        return false unless valid?

        result = create_or_update_record
        raise WeaviateRecord::Errors::InternalError, 'unable to save the record on Weaviate' unless result.is_a?(Hash)

        result
      end

      def create_or_update_record
        if @meta_attributes['id']
          @connection.update_call(@meta_attributes['id'], @attributes)
        else
          @connection.create_call(@attributes)
        end
      end

      def validate_record_for_destroy
        if @custom_selected
          raise WeaviateRecord::Errors::CustomQueriedRecordError,
                'cannot perform destroy action on custom selected record'
        end

        return true if @meta_attributes['id']

        @attributes.each_key { |key| @attributes[key] = nil }
        false
      end

      class_methods do
        def meta_attributes(record)
          meta = {}
          meta['id'] = record['id']
          meta['created_at'] = DateTime.strptime(record['creationTimeUnix'].to_s, '%Q')
          meta['updated_at'] = DateTime.strptime(record['lastUpdateTimeUnix'].to_s, '%Q')
          meta
        end
      end
    end
  end
end
