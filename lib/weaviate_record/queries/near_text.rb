module Weaviate
  module Queries
    # This module contains functions to perform near_text query (Context Based Search)
    module NearTextQuery
      # Do not change this value without testing the results of ALL possible values
      DEFAULT_DISTANCE = 0.55

      def near_text(*texts, distance: DEFAULT_DISTANCE)
        raise TypeError, 'invalid value for text' unless texts.all? { _1.is_a?(String) }
        raise TypeError, 'Invalid value for distance' unless distance.is_a?(Numeric)

        near_text_options[:distance] = distance
        near_text_options[:concepts] += texts.each { _1.gsub!('"', "'") }
        self.loaded = false
        self
      end

      private

      attr_reader :near_text_options

      def format_near_text
        near_text_options[:concepts].inject('{ concepts: [') do |acc, text|
          acc << '"' << text << '"' << ', '
        end.chop!&.chop!.to_s << '], distance: ' << near_text_options[:distance].to_s << ' }'
      end
    end
  end
end
