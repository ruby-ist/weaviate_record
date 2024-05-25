# frozen_string_literal: true

require 'zeitwerk'
require 'dotenv'
require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/conversions'

Dotenv.load
loader = Zeitwerk::Loader.for_gem
loader.setup

# Starting point of the gem
module WeaviateRecord
  def self.config
    @config ||= Struct.new(
      :near_text_default_distance,
      :schema_file_path
    ).new(0.55, "#{Object.const_defined?('Rails') ? Rails.root : Dir.pwd}/db/weaviate/schema.rb")
  end
end
