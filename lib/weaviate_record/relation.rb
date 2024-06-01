# frozen_string_literal: true

require 'forwardable'

module WeaviateRecord
  # This class is used to build weaviate queries
  class Relation
    extend Forwardable
    include Enumerable
    include Queries::Bm25
    include Queries::Count
    include Queries::Limit
    include Queries::NearText
    include Queries::NearVector
    include Queries::NearObject
    include Queries::Offset
    include Queries::Order
    include Queries::Select
    include Queries::Where
    include Queries::Ask
    include QueryBuilder

    def_delegators(:records, :empty?, :present?, :[], :first, :last)

    # :stopdoc:
    def initialize(klass)
      @select_options = { attributes: [], nested_attributes: {} }
      @near_text_options = { concepts: [], distance: WeaviateRecord.config.similarity_search_threshold }
      @limit = ENV['QUERY_DEFAULTS_LIMIT'] || 25
      @offset = 0
      @klass = klass
      @records = []
      @loaded = false
      @connection = WeaviateRecord::Connection.new(@klass)
    end
    # :startdoc:

    def each(&block)
      records.each(&block)
    end

    def inspect
      records
    rescue StandardError => e
      e
    end

    def destroy_all
      unless @where_query
        raise WeaviateRecord::Errors::MissingWhereCondition, 'must specifiy atleast one where condition'
      end

      response = @connection.delete_where(Queries::Where.to_ruby_hash(@where_query))
      return response['results'] if response.is_a?(Hash) && response.key?('results')

      raise WeaviateRecord::Errors::ServerError,
            response == '' ? 'Unauthorized' : response.dig('error', 'message').presence
    end

    alias all inspect
    alias to_a inspect

    private

    def records
      return @records if @loaded

      query = to_query
      custom_selected = query[:fields].present?
      query[:fields] = create_or_process_select_attributes(custom_selected, query[:fields])
      result = @connection.client.query.get(**query)
      @loaded = true
      @records = result.map { |record| @klass.new(custom_selected: custom_selected, **record) }
      @records
    end
  end
end
