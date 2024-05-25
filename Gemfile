# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# For validations, concerns and active support extensions
gem 'activemodel', '~> 7.1', '>= 7.1.3.3'

# For communicating with weaviate database
gem 'weaviate-ruby', '~> 0.8.10'

# For organizing and autoloading files
gem 'zeitwerk'

group :development, :test do
  # For managing environment variables
  gem 'dotenv'
end

group :lint do
  # For prettifying
  gem 'rubocop', require: false

  # Rubocop for rspec files
  gem 'rubocop-rspec', require: false
end

group :test do
  # For Unit testing
  gem 'rspec'
end
