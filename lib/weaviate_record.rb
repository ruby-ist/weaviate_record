# frozen_string_literal: true

require 'zeitwerk'
require 'active_model'
require 'active_support/core_ext/string/conversions'

loader = Zeitwerk::Loader.for_gem
loader.setup

# Starting point of the gem
module WeaviateRecord
  class << self
    # Configuration object for WeaviateRecord
    def config
      @config ||= Struct.new(
        :similarity_search_threshold,
        :schema_file_path,
        :sync_schema_on_load
      ).new(0.55, "#{Object.const_defined?('Rails') ? Rails.root : Dir.pwd}/db/weaviate/schema.rb", false)
    end

    # Used to configure WeaviateRecord, accepts a block and yields the configuration object
    #
    # ==== Example:
    #   WeaviateRecord.configure do |config|
    #     config.similarity_search_threshold = 0.6
    #     config.schema_file_path = "#{Rails.root}/db/weaviate/schema.rb"
    #     config.sync_schema_on_load = true
    #   end
    #
    # When sync_schema_on_load is set to true, the local schema will be synced
    # with the database schema when WeaviateRecord is loaded.
    def configure
      yield config if block_given?
      WeaviateRecord::Schema.update! if config.sync_schema_on_load && !WeaviateRecord::Schema.synced?
    end
  end
end
