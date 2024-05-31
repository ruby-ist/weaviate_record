# frozen_string_literal: true

require 'zeitwerk'
require 'active_model'
require 'active_support/core_ext/string/conversions'

loader = Zeitwerk::Loader.for_gem
loader.setup

# Starting point of the gem
module WeaviateRecord
  def self.config
    @config ||= Struct.new(
      :similarity_search_threshold,
      :schema_file_path
    ).new(0.55, "#{Object.const_defined?('Rails') ? Rails.root : Dir.pwd}/db/weaviate/schema.rb")

    yield @config if block_given?

    @config
  end
end
