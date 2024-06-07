# frozen_string_literal: true

module WeaviateRecord
  class Relation
    # This module contains methods which helps to build query for Weaviate
    module QueryBuilder
      # This will return the query that will be sent to Weaviate. More like +to_sql+ in ActiveRecord.
      #
      # ==== Example:
      #   Article.select(:title, :content).near_text('friendship movie').limit(5).offset(2).to_query
      # Returns:
      #   {:class_name=>"Article",
      #    :limit=>"5",
      #    :offset=>"2",
      #    :fields=>"title content",
      #    :near_text=>"{ concepts: [\"friendship movie\"], distance: 0.55 }"}
      def to_query
        query_params = basic_params
        fill_up_keyword_search_param(query_params)
        fill_up_similarity_search_param(query_params)
        fill_up_conditions_param(query_params)
        fill_up_sort_param(query_params)
        fill_up_question_param(query_params)

        query_params
      end

      private

      def basic_params
        { class_name: @klass.to_s, limit: @limit.to_s, offset: @offset.to_s,
          fields: combined_select_attributes }
      end

      def fill_up_keyword_search_param(query_params)
        query_params[:bm25] = @keyword_search if @keyword_search.present?
      end

      def fill_up_similarity_search_param(query_params)
        query_params[:near_text] = formatted_near_text_value unless @near_text_options[:concepts].empty?
        query_params[:near_vector] = @near_vector if @near_vector
        query_params[:near_object] = @near_object if @near_object
      end

      def fill_up_conditions_param(query_params)
        query_params[:where] = @where_query if @where_query
      end

      def fill_up_sort_param(query_params)
        # Weaviate doesn't support sorting with bm25 search at the time of writing this code.
        query_params[:sort] = @sort_options if @keyword_search.blank? && @sort_options
      end

      def fill_up_question_param(query_params)
        query_params[:ask] = @ask if @ask
      end
    end
  end
end
