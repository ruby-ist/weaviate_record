# frozen_string_literal: true

module WeaviateRecord
  # Base class for Weaviate records
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include Inspect
    include MethodMissing
    include Concerns::RecordConcern

    class << self
      extend Forwardable
      def_delegators(:relation, :all, :bm25, :limit, :near_text, :offset, :order, :select, :where)

      def create(**attributes_hash)
        record = new(**attributes_hash)
        record.save
        record
      end

      def find(id)
        result = Connection.new.find_call(id)
        if result.is_a?(Hash) && result['id']
          new(_additional: meta_attributes(result), **result['properties'])
        elsif result == ''
          raise WeaviateRecord::Errors::RecordNotFoundError, "Couldn't find Document with id=#{id}"
        else
          raise WeaviateRecord::Errors::ServerError, result['message']
        end
      end

      def count
        client = Connection.new.client
        result = client.query.aggs(class_name: to_s, fields: 'meta { count }')
        result.dig(0, 'meta', 'count')
      rescue StandardError
        raise WeaviateRecord::Errors::ServerError, "unable to get the count for #{self} collection."
      end

      private

      def relation
        WeaviateRecord::Relation.new(self)
      end

      def inherited(klass)
        super
        WeaviateRecord::Schema.find_collection(klass)
      end
    end

    def initialize(hash = {}, custom_selected: false, **attributes)
      attributes_hash = (hash.present? ? hash : attributes).deep_transform_keys(&:to_s)
      @connection = WeaviateRecord::Connection.new(collection_name)
      @custom_selected = custom_selected
      @attributes = {}
      @meta_attributes = attributes_hash['_additional'] || { 'id' => nil, 'creationTimeUnix' => nil,
                                                             'lastUpdateTimeUnix' => nil }
      run_attribute_handlers(attributes_hash)
    end

    def save
      result = validate_and_save
      return false unless result

      if result['error'].present?
        errors.add(:base, message: result['error'])
        false
      else
        @meta_attributes.merge!(self.class.meta_attributes(result))
        true
      end
    end

    def update(hash = {}, **attributes)
      attributes_hash = (hash.present? ? hash : attributes).deep_transform_keys(&:to_s)
      validate_record_for_update(attributes_hash)
      merge_attributes(attributes_hash)
      return false unless valid?

      result = @connection.update_call(@meta_attributes['id'], @attributes)
      raise WeaviateRecord::Errors::ServerError, 'unable to update the weaviate record' unless result.is_a?(Hash)

      errors.add(:base, message: result['error']) if result['error'].present?
      result['id'].present?
    end

    def destroy
      return self unless validate_record_for_destroy

      result = @connection.delete_call(@meta_attributes['id'])
      return freeze if result == true

      errors.add(:base, message: result['error']) if result['error'].present?
      false
    end

    def persisted?
      if @custom_selected || !respond_to?(:id)
        raise WeaviateRecord::Errors::CustomQueriedRecordError,
              'cannot perform persisted? action on custom queried record'
      end

      id.present?
    end

    private

    attr_reader :meta_attributes, :attributes, :custom_selected, :connection
  end
end
