## WeaviateRecord

An ORM for `Weaviate` vector database that follows the same conventions as the `ActiveRecord`.

This gem uses [weaviate-ruby](https://github.com/patterns-ai-core/weaviate-ruby) internally to connect with `Weaviate` DB.

### Installation

```bash
gem install weaviate_record
```

Or you can add it your `Gemfile` with:

```bash
bundle add weaviate_record
```

### Configuration

You can configure the `WeaviateRecord` gem by creating an initializer or setup file with following code:

```ruby
WeaviateRecord.configure do |config|

  # Sync the local schema with actual schema whenever this file is loaded if this value is set to true
  # Default value: false
  config.sync_schema_on_load = true

  # Threshold for similarity searches
  # Default value: 0.55
  config.similarity_search_threshold = 1.0

  # The file path where WeaviateRecord stores the local copy of your Weaviate database schema.
  # If Rails is installed in your project, the default value is "#{Rails.root}/db/weaviate/schema.rb"
  # Otherwise, the default value is "#{Dir.pwd}/db/weaviate/schema.rb"
  config.schema_file_path = "#{Rails.root}/db/weaviate/schema.rb"

end
```

### Usage

To use the `WeaviateRecord` for your model, simply inherit the base class.
`WeaviateRecord` mixins `ActiveModel::Validations`, so you can also add validations as you do for `ActiveRecord` models.

```ruby
class Article < WeaviateRecord::Base
  validate :title, presence: true

end
```

And that's all. Now, you can create and modify `weaviate` records as you do in the `ActiveRecord`. The syntax is exactly same with few naunces.
