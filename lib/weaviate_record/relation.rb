module WeaviateRecord
  class Relation
    extend Forwardable
    include Enumerable
    include Weaviate::Helpers::SchemaHelpers
    include Weaviate::Queries::Bm25Query
    include Weaviate::Queries::CountQuery
    include Weaviate::Queries::LimitQuery
    include Weaviate::Queries::NearTextQuery
    include Weaviate::Queries::OffsetQuery
    include Weaviate::Queries::OrderQuery
    include Weaviate::Queries::SelectQuery
    include Weaviate::Queries::WhereQuery

    def_delegators(:records, :empty?, :present?)

    def initialize(klass)
      @select_options = { attributes: [], nested_attributes: {} }
      @near_text_options = { concepts: [], distance: DEFAULT_DISTANCE }
      @limit = 1000
      @offset = 0
      @klass = klass.to_s
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
      query_params = { class_name: @klass, limit: @limit.to_s, offset: @offset.to_s, fields: combined_fields }
      query_params[:near_text] = format_near_text unless @near_text_options[:concepts].empty?
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

      client = Weaviate::Connection.create_client
      query = to_query
      custom_selection = query[:fields].present?
      query[:fields] = create_or_process_select_fields(custom_selection, query[:fields])
      result = client.query.get(**query)
      @loaded = true
      @records = result.map { |record| @klass.constantize.new(queried: custom_selection, **record) }
    end
  end
end
