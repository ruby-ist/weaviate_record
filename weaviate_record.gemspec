# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'weaviate_record'
  s.version     = '0.0.1'
  s.summary     = 'An ORM for Weaviate vector database'
  s.description = ''
  s.required_ruby_version = '>= 2.6.0'
  s.authors     = ['Sriram V']
  s.email       = 'srira.venkat@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://rubygems.org/gems/weaviate_record'
  s.license     = 'MIT'
  s.metadata    = { 'source_code_uri' => 'https://github.com/ruby-ist/weaviate_record',
                    'rubygems_mfa_required' => 'true' }

  s.add_runtime_dependency 'activemodel', '~> 7.1'
  s.add_runtime_dependency 'weaviate-ruby', '~> 0.1'
  s.add_runtime_dependency 'zeitwerk', '~> 2.6'
end
