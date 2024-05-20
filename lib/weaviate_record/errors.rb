# frozen_string_literal: true

# custom errors for Weaviate
module WeaviateRecord
  module Errors
    # Used when an un-queried attribute is accessed
    class MissingAttributeError < StandardError
    end

    # Used when an undefined attribute is accessed
    class InvalidAttributeError < StandardError
    end

    # Used when a collection is not found in the schema
    class CollectionNotFound < StandardError
    end

    # Used when a record without id is updated
    class MissingIdError < StandardError
    end

    # Used when a custom queried record is updated
    class CustomQueriedRecordError < StandardError
    end

    # Used when a meta attribute is updated
    class MetaAttributeError < StandardError
    end

    # Used when there is a problem with Weaviate
    class InternalError < StandardError
    end

    # Used when the Sorting order is invalid
    class SortingOptionError < StandardError
    end

    # Used when the where query is invalid
    class InvalidWhereQueryError < StandardError
    end

    # Used when the operator in where query is invalid
    class InvalidOperatorError < StandardError
    end

    # Used when the value type in where query is invalid
    class InvalidValueTypeError < StandardError
    end

    # Used when the record not found
    class RecordNotFoundError < StandardError
    end

    # Used for the errors thrown by weaviate server
    class ServerError < StandardError
    end

    # Used when the schema is not in sync with the weaviate database
    class SchemaSyncError < StandardError
    end

    # Used for errors occurring during migrations
    class MigrationError < StandardError
    end
  end
end
