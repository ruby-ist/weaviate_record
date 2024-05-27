# frozen_string_literal: true

module WeaviateRecord
  # This class is used to build weaviate queries
  class Relation
    extend Forwardable
    include Enumerable
    include Queries::Bm25
    include Queries::Count
    include Queries::Limit
    include Queries::NearText
    include Queries::Offset
    include Queries::Order
    include Queries::Select
    include Queries::Where

    def_delegators(:records, :empty?, :present?)

    def initialize(klass)
      @select_options = { attributes: [], nested_attributes: {} }
      @near_text_options = { concepts: [], distance: WeaviateRecord.config.near_text_default_distance }
      @limit = ENV['QUERY_DEFAULTS_LIMIT'] || 25
      @offset = 0
      @klass = klass
      @records = []
      @loaded = false
      @connection = WeaviateRecord::Connection.new
    end

    def each(&block)
      records.each(&block)
    end

    def inspect
      records
    end

    alias all inspect
    alias to_a inspect

    def to_query
      query_params = { class_name: @klass.to_s, limit: @limit.to_s, offset: @offset.to_s,
                       fields: combined_select_attributes }
      query_params[:near_text] = formatted_near_text_value unless @near_text_options[:concepts].empty?
      query_params[:bm25] = "{ query: #{@keyword_search.inspect} }" if @keyword_search.present?
      query_params[:where] = @where_query if @where_query
      # Weaviate doesn't support sorting with bm25 search at the time of writing this code.
      query_params[:sort] = @sort_options if @keyword_search.blank? && @sort_options
      query_params
    end

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
