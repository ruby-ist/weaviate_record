# frozen_string_literal: true

require 'zeitwerk'
require 'active_model'
require 'active_support/core_ext/string/conversions'

loader = Zeitwerk::Loader.for_gem
loader.setup

# Starting point of the gem
module WeaviateRecord
  class << self
    def config
      @config ||= Struct.new(
        :similarity_search_threshold,
        :schema_file_path,
        :sync_schema_on_load
      ).new(0.55, "#{Object.const_defined?('Rails') ? Rails.root : Dir.pwd}/db/weaviate/schema.rb", false)
    end

    def configure
      yield config if block_given?
      WeaviateRecord::Schema.update! if config.sync_schema_on_load && !WeaviateRecord::Schema.synced?
    end
  end
end
