# frozen_string_literal: true

module WeaviateRecord
  # Schema module stores the schema of all Weaviate Collections
  class Schema
    def self.all_collections
      { classes: [] }
    end
  end
end
