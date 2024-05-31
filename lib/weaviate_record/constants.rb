# frozen_string_literal: true

module WeaviateRecord
  # A module to store all Weaviate related constants
  module Constants
    SPECIAL_ATTRIBUTE_MAPPINGS = { 'feature_projection' => 'featureProjection',
                                   'created_at' => 'creationTimeUnix',
                                   'updated_at' => 'lastUpdateTimeUnix',
                                   'explain_score' => 'explainScore' }.freeze

    OPERATOR_MAPPING_HASH = { '=' => 'Equal', '==' => 'Equal', '!=' => 'NotEqual',
                              '>' => 'GreaterThan', '<' => 'LessThan', '>=' => 'GreaterThanEqual',
                              '<=' => 'LessThanEqual', 'LIKE' => 'Like', 'CONTAINS_ANY' => 'ContainsAny',
                              'CONTAINS_ALL' => 'ContainsAll' }.freeze

    TYPE_MAPPING_HASH = { Integer => 'valueInt', String => 'valueText', Array => 'valueText',
                          Float => 'valueNumber', TrueClass => 'valueBoolean', FalseClass => 'valueBoolean' }.freeze

    META_ATTRIBUTES = %w[vector certainty distance feature_projection classification
                         creation_at updated_at score explain_score summary].freeze

    UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i.freeze
  end
end

WeaviateRecord::Constants.freeze
