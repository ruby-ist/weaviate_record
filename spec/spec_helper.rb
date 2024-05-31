# frozen_string_literal: true

require_relative '../lib/weaviate_record'
require_relative 'models/article'
require 'dotenv'
require 'simplecov'

Dotenv.load
SimpleCov.start
