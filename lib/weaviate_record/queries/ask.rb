# frozen_string_literal: true

module WeaviateRecord
  module Queries # :nodoc:
    # This module provides method for ask query
    module Ask
      def ask(question, on_attributes: [])
        question.to_str
        raise WeaviateRecord::Errors::EmptyPrompt, 'text cannot be empty' if question.empty?

        attributes = on_attributes.map(&:to_s)
        @ask = "{ question: #{question.gsub('"', "'").inspect}" \
               "#{", properties: #{attributes}" if attributes.present?} }"
        @loaded = false
        self
      end
    end
  end
end
