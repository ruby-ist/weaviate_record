# frozen_string_literal: true

module WeaviateRecord
  class Relation
    extend Forwardable
    include Enumerable
    include WeaviateRecord::Helpers::SchemaHelpers
    include WeaviateRecord::Queries::Bm25
    include WeaviateRecord::Queries::Count
    include WeaviateRecord::Queries::Limit
    include WeaviateRecord::Queries::NearText
    include WeaviateRecord::Queries::Offset
    include WeaviateRecord::Queries::Order
    include WeaviateRecord::Queries::Select
    include WeaviateRecord::Queries::Where

    def_delegators(:records, :empty?, :present?, :all)

    def initialize(klass)
      @select_options = { attributes: [], nested_attributes: {} }
      @near_text_options = { concepts: [], distance: DEFAULT_DISTANCE }
      @limit = ENV['WEAVIATE_DEFAULT_LIMIT'] || 25
      @offset = 0
      @klass = klass
      @records = []
      @loaded = false
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
      query_params = { class_name: @klass.to_s, limit: @limit.to_s, offset: @offset.to_s, fields: combined_fields }
      query_params[:near_text] = formatted_near_text_value unless @near_text_options[:concepts].empty?
      query_params[:bm25] = "{ query: #{@keyword_search.inspect} }" if @keyword_search.present?
      query_params[:where] = @where_query if @where_query
      # Weaviate doesn't support sorting with bm25 search at the time of writing this code.
      query_params[:sort] = @sort_options if @keyword_search.blank? && @sort_options
      query_params
    end

    private

    attr_writer :loaded

    def records
      return @records if @loaded

      query = to_query
      custom_selection = query[:fields].present?
      query[:fields] = create_or_process_select_fields(custom_selection, query[:fields])
      result = WeaviateRecord::Connection.new.query.get(**query)
      @loaded = true
      @records = result.map { |record| @klass.new(queried: custom_selection, **record) }
    end
  end
end
