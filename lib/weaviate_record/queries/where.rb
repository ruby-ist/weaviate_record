# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains function to perform where query on Weaviate
    module Where
      def where(query = '', *values, **kw_args)
        validate_arguments(query, values, kw_args)
        keyword_query = process_keyword_conditions(kw_args)
        string_query = process_string_conditions(query, *values)
        combined_query = combine_queries(keyword_query, string_query)
        @where_query = @where_query ? create_logical_condition(@where_query, 'And', combined_query) : combined_query
        @loaded = false
        self
      end

      def self.to_ruby_hash(string_condition)
        pattern = /(?<=\s)\w+:|(?<=operator:\s)\w+/
        keys_and_operator = string_condition.scan(pattern).uniq
        json_equivalent = keys_and_operator.map { |i| i.end_with?(':') ? "#{i[0...-1].inspect}:" : i.inspect }
        JSON.parse string_condition.gsub(pattern, keys_and_operator.zip(json_equivalent).to_h)
      rescue StandardError
        raise WeaviateRecord::Errors::WhereQueryConversionError, 'invalid where query format'
      end

      private

      def validate_arguments(query, values, kw_args)
        if values.empty? && kw_args.empty?
          raise WeaviateRecord::Errors::InvalidWhereQueryError, 'invalid argument for where query'
        end

        return unless values.size != query.count('?')

        raise WeaviateRecord::Errors::InvalidWhereQueryError, 'invalid number of arguments'
      end

      def process_keyword_conditions(hash)
        return nil if hash.empty?

        conditions = hash.each_pair.map do |key, value|
          create_query_condition([key.to_s, value.is_a?(Array) ? 'CONTAINS_ANY' : '=', value])
        end
        conditions.inject { |acc, condition| create_logical_condition(acc, 'AND', condition) }
      end

      def process_string_conditions(query, *values)
        return nil unless query.present? && values.present?

        logical_operator_match = /\s+(AND|OR)\s+/i.match(query)
        return create_query_condition_from_string(query, values) unless logical_operator_match

        pre_condition = create_query_condition_from_string(logical_operator_match.pre_match, values)
        post_condition = process_string_conditions(logical_operator_match.post_match, *values)

        create_logical_condition(pre_condition, logical_operator_match[1], post_condition)
      end

      def create_query_condition_from_string(condition, values)
        equation = condition.split
        raise WeaviateRecord::Errors::InvalidWhereQueryError, 'unable to process the query' unless equation.size == 3
        raise WeaviateRecord::Errors::InvalidWhereQueryError, 'insufficient values for formatting' if values.empty?

        equation[-1] = values.shift
        create_query_condition(equation)
      end

      def combine_queries(first_query, second_query)
        if first_query.present? && second_query.present?
          create_logical_condition(first_query, 'And', second_query)
        else
          first_query.presence || second_query
        end
      end

      def create_query_condition(equation)
        return null_condition(equation[0]) if equation[2].nil?

        handle_timestamps_condition(equation)
        "{ path: [\"#{equation[0]}\"], " \
          "operator: #{map_operator(equation[1])}, " \
          "#{map_value_type(equation[2])}: #{equation[2].inspect} }"
      end

      def handle_timestamps_condition(equation_array)
        return nil unless equation_array[0] == 'created_at' || equation_array[0] == 'updated_at'

        equation_array[0] = "_#{WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS[equation_array[0]]}"
        equation_array[2] = equation_array[2].to_datetime.strftime('%Q')
      end

      def null_condition(attribute)
        "{ path: [\"#{attribute}\"], operator: IsNull, valueBoolean: true }"
      end

      def create_logical_condition(pre_condition, operator, post_condition)
        "{ operator: #{operator.capitalize}, " \
          "operands: [#{pre_condition}, #{post_condition}] }"
      end

      def map_operator(operator)
        WeaviateRecord::Constants::OPERATOR_MAPPING_HASH.fetch(operator) do
          raise WeaviateRecord::Errors::InvalidOperatorError, "Invalid conditional operator #{operator}"
        end
      end

      def map_value_type(value)
        WeaviateRecord::Constants::TYPE_MAPPING_HASH.fetch(value.class) do |klass|
          raise WeaviateRecord::Errors::InvalidValueTypeError, "Invalid value type #{klass} for comparison"
        end
      end
    end
  end
end
