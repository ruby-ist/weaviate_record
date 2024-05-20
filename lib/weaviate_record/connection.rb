# frozen_string_literal: true

require 'weaviate'

module Weaviate
  # This class is used to create a Weaviate connection
  class Connection
    class << self
      STRUCTURE_FILE_BOILERPLATE = lambda do |schema|
        <<~RUBY
          # frozen_string_literal: true

          module Weaviate
            # Structure class stores the schema of all Weaviate Collections
            # Rewrite #.current definition as { classes: {} } for first time initialization
            # and then it will automatically get updated as Weaviate schema changes
            class Structure
              def self.current # rubocop:disable Metrics/MethodLength
                #{schema}
              end
            end
          end
        RUBY
      end

      def create_client
        @create_client ||= Weaviate::Client.new(url: ENV['WEAVIATE_DATABASE_URL'])
      end

      def update_schema
        File.open(structure_file_name, 'w') do |f|
          f.write STRUCTURE_FILE_BOILERPLATE[pretty_schema]
        end
        rubocop_format_file
      end

      protected

      def pretty_schema
        create_client.schema.list
                     .deep_symbolize_keys!
                     .pretty_inspect
      end

      def rubocop_format_file
        # To prettify the generated file
        system("rubocop -a #{structure_file_name}", out: File::NULL)
      end

      def structure_file_name
        "#{Rails.root}/lib/weaviate/structure.rb"
      end
    end
  end
end
