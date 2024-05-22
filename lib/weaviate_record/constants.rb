# frozen_string_literal: true

module WeaviateRecord
  # A module to store all Weaviate related constants
  module Constants
    SPECIAL_ATTRIBUTE_MAPPINGS = { 'feature_projection' => 'featureProjection',
                                   'created_at' => 'creationTimeUnix',
                                   'updated_at' => 'lastUpdateTimeUnix' }.freeze

    OPERATOR_MAPPING_HASH = { '=' => 'Equal', '==' => 'Equal', '!=' => 'NotEqual',
                              '>' => 'GreaterThan', '<' => 'LessThan', '>=' => 'GreaterThanEqual',
                              '<=' => 'LessThanEqual', 'LIKE' => 'Like', 'CONTAINS_ANY' => 'ContainsAny',
                              'CONTAINS_ALL' => 'ContainsAll' }.freeze

    TYPE_MAPPING_HASH = { Integer => 'valueInt', String => 'valueText', Array => 'valueText',
                          Float => 'valueNumber', TrueClass => 'valueBoolean', FalseClass => 'valueBoolean' }.freeze

    META_ATTRIBUTES = %w[vector certainty distance feature_projection classification creation_at updated_at].freeze

    NEAR_TEXT_DEFAULT_DISTANCE = 0.55
  end
end

WeaviateRecord::Constants.freeze
