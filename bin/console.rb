# frozen_string_literal: true

require 'irb'
require 'irb/completion'
require 'dotenv'

Dotenv.load

require_relative '../lib/weaviate_record'

class Article < WeaviateRecord::Base; end

IRB.start
