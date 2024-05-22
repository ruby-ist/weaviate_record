# frozen_string_literal: true

module WeaviateRecord
  module Queries
    # This module contains functions to perform near_text query (Context Based Search)
    module NearTextQuery
      def near_text(*texts, distance: WeaviateRecord::Constants::NEAR_TEXT_DEFAULT_DISTANCE)
        raise TypeError, 'invalid value for text' unless texts.all? { |text| text.is_a?(String) }
        raise TypeError, 'Invalid value for distance' unless distance.is_a?(Numeric)

        near_text_options[:distance] = distance
        near_text_options[:concepts] += texts.map! { |text| text.gsub('"', "'") }
        self.loaded = false
        self
      end

      private

      attr_reader :near_text_options

      def formatted_near_text_value
        texts = near_text_options[:concepts].map { |text| text.inspect }.join(', ')

        "{ concepts: [#{texts}] , distance: #{near_text_options[:distance].to_s} }"
      end
    end
  end
end
