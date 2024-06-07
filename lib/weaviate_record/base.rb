# frozen_string_literal: true

require 'forwardable'

module WeaviateRecord
  # Base class for the models to inherit from and to interact with the respective collection in weaviate.
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include Inspect
    include MethodMissing
    include Concerns::RecordConcern

    class << self
      extend Forwardable
      def_delegators(:relation, :all, :bm25, :limit, :near_text, :near_vector, :near_object,
                     :offset, :order, :select, :where, :ask, :destroy_all, :first, :last)

      # Creates a new weaviate record and saves it and returns the record.
      # Takes a key value pair of attributes that the record should be initialized with.
      # If the record is not saved, it returns the unsaved record object with errors.
      #
      # ==== Example:
      #  Article.create(title: 'Hello World', content: 'This is the content of the article')
      #
      #  # => #<Article:0x0000000105468ab0 id: "8280210b-9372-4e70-a045-beb7c12a9a24" ...>
      def create(**attributes_hash)
        record = new(**attributes_hash)
        record.save
        record
      end

      # Takes an _uuid_ and returns the record with that _uuid_.
      # If the record is not found, it raises a +RecordNotFoundError+.
      #
      # ==== Example:
      #   Article.find('f3b1b3b1-0b3b-4b3b-8b3b-0b3b3b3b3b3b')
      #
      #   #<Article:0x0000000105468ab0 id: "8280210b-9372-4e70-a045-beb7c12a9a24" ...>
      def find(id)
        result = connection.find_call(id)
        if result.is_a?(Hash) && result['id']
          new(_additional: meta_attributes(result), **result['properties'])
        elsif result == ''
          raise WeaviateRecord::Errors::RecordNotFoundError, "Couldn't find record with id=#{id}"
        else
          raise WeaviateRecord::Errors::ServerError, result['message']
        end
      end

      # Returns the count of all records in the collection.
      #
      # ==== Example:
      #    class Article < WeaviateRecord::Base
      #    end
      #
      #    Article.count # => 0
      #
      #    Article.create(title: 'Hello World', content: 'This is the content of the article')
      #
      #    Article.count # => 1
      def count
        result = connection.client.query.aggs(class_name: to_s, fields: 'meta { count }')
        result.dig(0, 'meta', 'count')
      rescue StandardError
        raise WeaviateRecord::Errors::ServerError, "unable to get the count for #{self} collection."
      end

      # Takes an _uuid_ and checks whether a record with that id exists or not.
      #
      # ==== Example:
      #   Article.exists?('f3b1b3b1-0b3b-4b3b-8b3b-0b3b3b3b3b3b')  # => true
      #   Article.exists?('random_uuid')  # => false
      def exists?(id)
        connection.check_existence(id)
      end

      private

      def connection
        @connection ||= Connection.new(self)
      end

      def relation
        WeaviateRecord::Relation.new(self)
      end

      def inherited(klass)
        WeaviateRecord::Schema.find_collection(klass)
        super
      end
    end

    # Creates a new record with the given attributes.
    # The attributes can be passed as a hash or as key value pairs.
    # It does not save the record in the weaviate database.
    #
    #
    # ==== Example:
    #  Article.new(title: 'Hello World', content: 'This is the content of the article')
    #
    #  # => #<Article:0x0000000105468ab0 ... "Hello World", content: "This is the content of the article">
    #
    #  Article.title # => "Hello World"
    #  Article.content # => "This is the content of the article"
    #
    #  Article.title = 'Not Hello World'
    #  Article.title # => "Not Hello World"
    #
    #  Article.persisted? # => false
    #
    #
    # The +custom_selected+ parameter is used to indicate whether the attributes are custom picked.
    # If the attributes are custom picked, the attribute readers will be defined only for the selected attributes.
    # The record with custom_selected as true cannot be saved, updated, or destroyed.
    def initialize(hash = {}, custom_selected: false, **attributes)
      attributes_hash = (hash.present? ? hash : attributes).deep_transform_keys(&:to_s)
      @connection = WeaviateRecord::Connection.new(collection_name)
      @custom_selected = custom_selected
      @attributes = {}
      @meta_attributes = attributes_hash['_additional'] || { 'id' => nil, 'creationTimeUnix' => nil,
                                                             'lastUpdateTimeUnix' => nil }
      run_attribute_handlers(attributes_hash)
    end

    # Saves the record in the weaviate database.
    # Returns true if the record is saved successfully. Otherwise, it returns false.
    # If the record is not saved successfully, it adds the errors to the record.
    # If the record is already saved, it updates the record.
    #
    # ==== Example:
    #  class Article < WeaviateRecord::Base
    #    validates :title, presence: true
    #  end
    #
    #  article = Article.new(title: 'Hello World', content: 'This is the content of the article')
    #  article.save # => true
    #
    #  article.title = 'New title'
    #  article.save # => true
    #
    #  article.title # => "New title"
    #
    #  article = Article.new(title: '')
    #  article.save # => false
    #  article.errors.full_messages # => ["Title can't be blank"]
    #
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

    # Updates the record in the weaviate database.
    # Returns true if the record is updated successfully. Otherwise, it returns false.
    # If the record is not updated successfully, it adds the errors to the record.
    #
    # ==== Example:
    #  class Article < WeaviateRecord::Base
    #   validates :title, presence: true
    #  end
    #
    #  article = Article.new(title: 'Hello World', content: 'This is the content of the article')
    #  article.save
    #
    #  article.update(title: 'Not Hello World') # => true
    #  article.title # => "Not Hello World"
    #
    #  article.update(title: '') # => false
    #  article.errors.full_messages # => ["Title can't be blank"]
    #
    # If you try to update the meta attribute, it will raise an error
    #
    # ==== Example:
    #  article.update(id: 'new_id')
    #  # => WeaviateRecord::Errors::MetaAttributeError: 'cannot update meta attributes'
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

    # Destroys the record in the weaviate database.
    # Returns true if the record is destroyed successfully. Otherwise, it returns false.
    # If the record is the original record with valid id, it freezes the existing record object.
    # If the record does not have a valid id, it converts all the attributes to nil.
    #
    # ==== Example:
    #  article = Article.new(title: 'Hello World', content: 'This is the content of the article')
    #
    #  article.destroy # => false
    #  article.title   # => nil
    #
    #  article.title = 'New title'
    #  article.save
    #
    #  article.destroy # => true
    #
    #  article.frozen? # => true
    def destroy
      return self unless validate_record_for_destroy

      result = @connection.delete_call(@meta_attributes['id'])
      return freeze if result == true

      errors.add(:base, message: result['error']) if result['error'].present?
      false
    end

    # Checks whether the record is saved in the weaviate database or not.
    # If the record is saved, it returns true. Otherwise, it returns false.
    #
    # ==== Example:
    #  article = Article.new(title: 'Hello World', content: 'This is the content of the article')
    #  article.save
    #  article.persisted? # => true
    def persisted?
      if @custom_selected || !respond_to?(:id)
        raise WeaviateRecord::Errors::CustomQueriedRecordError,
              'cannot perform persisted? action on custom queried record'
      end

      id.present?
    end
  end
end
