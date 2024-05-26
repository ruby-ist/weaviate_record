# frozen_string_literal: true

module WeaviateRecord
  # This module contains methods that helps to build, maintain and read data from weaviate schema
  class Schema
    class << self
      STRUCTURE_FILE_BOILERPLATE = lambda do |schema|
        <<~RUBY
          # frozen_string_literal: true

          module WeaviateRecord
            # Schema module stores the schema of all Weaviate Collections
            class Schema
              def self.all_collections # rubocop:disable Metrics/MethodLength
                #{schema}
              end
            end
          end
        RUBY
      end

      def update!
        create_weaviate_db_dir!
        File.write(WeaviateRecord.config.schema_file_path, STRUCTURE_FILE_BOILERPLATE[pretty_schema])
        rubocop_format_file
      end

      def find_collection(klass)
        load WeaviateRecord.config.schema_file_path
        collection_schema = all_collections[:classes].find { |collection| collection[:class] == klass.to_s }
        if collection_schema.nil?
          raise WeaviateRecord::Errors::CollectionNotFound, "Collection #{klass} not found in the schema"
        end

        new(collection_schema)
      end

      private

      def pretty_schema
        WeaviateRecord::Connection.new.client.schema.list
                                  .deep_symbolize_keys!
                                  .pretty_inspect
      end

      def rubocop_format_file
        # To prettify the generated file
        system("rubocop -a #{WeaviateRecord.config.schema_file_path}", out: File::NULL)
      end

      def create_weaviate_db_dir!
        dir_path = WeaviateRecord.config.schema_file_path.delete_suffix('/schema.rb')
        FileUtils.mkdir_p(dir_path)
      end
    end

    def initialize(schema)
      @schema = schema
    end

    def attributes_list
      @schema[:properties].map { |property| property[:name] }
    end

    private_class_method :new
    attr_reader :schema
  end
end
