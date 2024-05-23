# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to perform where query on Weaviate
    module Where
      def where(query = '', *values, **kw_args)
        if values.empty? && kw_args.empty?
          raise Weaviate::Errors::InvalidWhereQueryError, 'invalid argument for where query'
        end
        raise Weaviate::Errors::InvalidWhereQueryError, 'invalid number of arguments' if values.size != query.count('?')

        keyword_query = process_keyword_conditions(kw_args)
        string_query = process_string_conditions(query, *values)
        combined_query = combine_queries(keyword_query, string_query)
        self.where_query = where_query ? format_logical_condition(where_query, 'And', combined_query) : combined_query
        self.loaded = false
        self
      end

      private

      attr_accessor :where_query

      def process_keyword_conditions(hash)
        return nil if hash.empty?

        conditions = hash.each_pair.map do |key, value|
          format_condition([key.to_s, value.is_a?(Array) ? 'CONTAINS_ANY' : '=', value])
        end
        conditions.inject { |acc, condition| format_logical_condition(acc, 'AND', condition) }
      end

      def process_string_conditions(query, *values)
        return nil if query.empty? && values.empty?

        logical_operator_match = /\s+(AND|OR)\s+/i.match(query)
        return format_where_option(query, values) unless logical_operator_match

        pre_condition = format_where_option(logical_operator_match.pre_match, values)
        post_condition = process_string_conditions(logical_operator_match.post_match, *values)
        format_logical_condition(pre_condition, logical_operator_match[1], post_condition)
      end

      def format_where_option(condition, values)
        equation = condition.split(' ')
        raise Weaviate::Errors::InvalidWhereQueryError, 'unable to process the query' unless equation.size == 3
        raise Weaviate::Errors::InvalidWhereQueryError, 'insufficient values for formatting' if values.empty?

        equation[-1] = values.shift
        format_condition(equation)
      end

      def combine_queries(first_query, second_query)
        if first_query.present? && second_query.present?
          format_logical_condition(first_query, 'And', second_query)
        else
          first_query.presence || second_query
        end
      end

      def format_condition(equation)
        return null_condition(equation[0]) if equation[2].nil?

        handle_timestamps_condition(equation)
        "{ path: [\"#{equation[0]}\"], " \
          "operator: #{convert_operator(equation[1])}, " \
          "#{value_type(equation[2])}: #{equation[2].inspect} }"
      end

      def handle_timestamps_condition(equation_array)
        return nil unless equation_array[0] == 'created_at' || equation_array[0] == 'updated_at'

        equation_array[0] = "_#{Weaviate::Constants::SPECIAL_ATTRIBUTE_MAPPINGS[equation_array[0]]}"
        equation_array[2] = equation_array[2].to_datetime.strftime('%Q')
      end

      def null_condition(attribute)
        "{ path: [\"#{attribute}\"], operator: IsNull, valueBoolean: true }"
      end

      def format_logical_condition(pre_condition, operator, post_condition)
        "{ operator: #{operator.capitalize}, " \
          "operands: [#{pre_condition}, #{post_condition}] }"
      end

      def convert_operator(operator)
        operator_string = Weaviate::Constants::OPERATOR_MAPPING_HASH[operator]
        raise Weaviate::Errors::InvalidOperatorError, "Invalid conditional operator #{operator}" if operator_string.nil?

        operator_string
      end

      def value_type(value)
        type = Weaviate::Constants::TYPE_MAPPING_HASH[value.class]
        raise Weaviate::Errors::InvalidValueTypeError, "Invalid value type #{value.class} for comparison" if type.nil?

        type
      end
    end
  end
end
