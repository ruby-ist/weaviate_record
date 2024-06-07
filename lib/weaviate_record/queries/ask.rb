# frozen_string_literal: true

module WeaviateRecord
  module Queries # :nodoc:
    # This module provides method for ask query
    module Ask
      # Answers the question using the QnA module with the help of the records in the database.
      #
      # Requires QNA_INFERENCE_API to be set in the weaviate instance.
      # The answer will be available in the _result_ key of the _answer_ meta attribute.
      #
      # You can also optionally pass an array of attributes to searched for the answer.
      #
      # ==== Example:
      #   Article.create(content: 'the name is Sparrow')
      #   Article.select(_additional: { answer: :result }).ask('whats your name?')
      #   # => [#<Article:0x0000000109a85de0 id: nil answer: {"result"=>"Sparrow"}>]
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
