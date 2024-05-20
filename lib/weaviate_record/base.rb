module WeaviateRecord
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include Weaviate::Helpers::RecordHelpers
    include Weaviate::Helpers::SchemaHelpers
    include Weaviate::Record::AttributeHandlers
    include Weaviate::Record::Inspect
    include Weaviate::Record::MethodMissing
    include Weaviate::Record::QueryHandlers
    attr_reader :additional, :attributes, :queried_record
    private :additional, :attributes, :queried_record

    class << self
      extend Forwardable
      def_delegators(:relation, :all, :bm25, :limit, :near_text, :offset, :order, :select, :where)

      def create(**attributes_hash)
        record = new(**attributes_hash)
        record.save
        record
      end

      def find(id)
        result = find_call(id)
        if result.is_a?(Hash) && result['id']
          new(_additional: additional_attributes(result), **result['properties'])
        elsif result == ''
          raise Weaviate::Errors::RecordNotFoundError, "Couldn't find Document with id=#{id}"
        else
          raise Weaviate::Errors::ServerError, result['message']
        end
      end

      def count
        client = Weaviate::Connection.create_client
        result = client.query.aggs(class_name: to_s, fields: 'meta { count }')
        result.dig(0, 'meta', 'count')
      rescue StandardError
        raise Weaviate::Errors::ServerError, "unable to get the count for #{self} collection."
      end

      private

      def relation
        Weaviate::Relation.new(to_s)
      end
    end

    def initialize(hash = {}, queried: false, **attributes)
      attributes_hash = (hash.present? ? hash : attributes).deep_transform_keys(&:to_s)
      @client = Weaviate::Connection.create_client
      @queried_record = queried
      @attributes = {}
      @additional = attributes_hash['_additional'] || { 'id' => nil, 'creationTimeUnix' => nil,
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
        @additional.merge!(self.class.additional_attributes(result))
        true
      end
    end

    def update(hash = {}, **attributes)
      attributes_hash = (hash.present? ? hash : attributes).deep_transform_keys(&:to_s)
      update_validation_check(attributes_hash)
      merge_attributes(attributes_hash)
      return false unless valid?

      result = update_call(@additional['id'], @attributes)
      raise Weaviate::Errors::ServerError, 'unable to update the weaviate record' unless result.is_a?(Hash)

      errors.add(:base, message: result['error']) if result['error'].present?
      result['id'].present?
    end

    def destroy
      return self unless validate_record_for_destroy

      result = delete_call(@additional['id'])
      return freeze if result == true

      errors.add(:base, message: result['error']) if result['error'].present?
      false
    end

    def persisted?
      if @queried_record || !respond_to?(:id)
        raise Weaviate::Errors::CustomQueriedRecordError, 'cannot perform persisted? action on custom queried record'
      end

      id.present?
    end
  end
end
