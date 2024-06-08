## WeaviateRecord

![Tests status](https://github.com/ruby-ist/weaviate_record/actions/workflows/gem-push.yml/badge.svg)
![Gem Version](https://badge.fury.io/rb/weaviate_record.svg)
[![Docs](http://img.shields.io/badge/yard-docs-chartreuse.svg)](http://rubydoc.info/gems/weaviate_record)
[![License](https://img.shields.io/badge/license-MIT-limegreen.svg)](https://github.com/ruby-ist/weaviate_record/blob/main/LICENSE.txt)

An ORM for `Weaviate` vector database that follows the same conventions as the `ActiveRecord`. Bring the power of Vector database and Retrieval augmented generation (RAG) to your Ruby application.

This gem uses [weaviate-ruby](https://github.com/patterns-ai-core/weaviate-ruby) internally to connect with `Weaviate` DB.

### Installation

```bash
gem install weaviate_record
```

Or you can add it your `Gemfile` with:

```bash
bundle add weaviate_record
```

### Prerequisites

`WeaviateRecord` needs a weaviate database running in your local machine or cloud. For creating an weaviate instance on your local machine, please use weaviate's official [configurator](https://weaviate.io/developers/weaviate/installation/docker-compose#configurator).

After creating an instance, set an env variable `WEAVIATE_DATABASE_URL` with the database url. If you have authentication enabled on weaviate, set the API key to `WEAVIATE_API_KEY`.

If you want to use different vectorizer module instead of transformers, please set the env variable `WEAVIATE_VECTORIZER_MODULE` to your model and `WEAVIATE_VECTORIZER_API_KEY` to your module's API key.

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

### Creating Collection in Weaviate

`WeaviateRecord` does not have a separate DSL for creating collection like `ActiveRecord`. However there are two things you have to keep in mind while creating a collection.

1. you should add [indexTimestamps](https://weaviate.io/developers/weaviate/config-refs/schema#invertedindexconfig--indextimestamps) and [indexNullState](https://weaviate.io/developers/weaviate/config-refs/schema#invertedindexconfig--indexnullstate) to your collection schema. Otherwise, timestamps and null based conditions won't work.

```ruby
WeaviateRecord::Connection.new.client.create(
  class_name: 'Article',
  properties: [...],
  inverted_index_config: {
    "indexNullState": true,
    "indexTimestamps": true
  }
)
```

Note: You can create a new `Weaviate::Client` instance by calling `#client` method on any `WeaviateRecord::Connection` instances. These object will automatically use the values you assigned on env variables.

2. Wherever you are modifying `Weaviate` schema, be it in rake or migration, or any other file, be sure to call the method `WeaviateRecord::Schema.update!`. It will automatically update your local copy of the database schema.

### Usage

To use the `WeaviateRecord` for your model, simply inherit the base class.
`WeaviateRecord` mixins `ActiveModel::Validations`, so you can also add validations as you do for `ActiveRecord` models.

```ruby
class Article < WeaviateRecord::Base
  validate :title, presence: true

end
```

And that's all. Now, you can create and modify `weaviate` records as you do in the `ActiveRecord`. The syntax is exactly same with few naunces.

Below are all the basic methods defined for CRUD operations. Their syntax and their behaviour is same as their `ActiveRecord` equivalent

- [new](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase:initialize)
- [create](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase%2Ecreate)
- [save](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase:save)
- [find](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase%2Efind)
- [update](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase:update)
- [destroy](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase:destroy)
- [count](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase%2Ecount)
- [persisted?](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FBase:persisted%3F)

For batch operations,

- [destory_all](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FRelation:destroy_all) (Needs atleast one where condition)

For query interface, we have

- [select](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FSelect:select)
- [where](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FWhere:where)
- [order](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FOrder:order)
- [limit](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FLimit:limit)
- [offset](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FOffset:offset)

For debugging purposes, there is one method called [#to_query](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FRelation%2FQueryBuilder:to_query) which behaves likes `#to_sql` in `ActiveRecord`.

All the above methods work exactly the same way those `ActiveRecord` methods do. Apart from these, all the methods comes from `ActiveModel::Validations` and `Enumerable` modules are also available, and then there are few other methods where `Weaviate` truly shines.

#### Keyword Search

To use the weaviate's special keyword based search on your model, there is one method called [#bm25](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FBm25:bm25). There are some limitations you might be facing while using `#bm25`. Notable one is that you cannot chain `#count` or `#order` method with `#bm25`.

```ruby
Article.bm25('keyword').count # bm25 will be ignored here
Article.bm25('keyword').order # order will be ignored here
```

There are some scenarios where `bm25` search does overfitting. To mitigate that, you can query the meta attribute `score` along with the search and filter them once again for relevance.

```ruby
Article.select(_additional: :score).bm25('You Keyword').take_while do |article|
  article.score >= KEYWORD_SEARCH_THRESHOLD
end
```

#### Similarity Search

Weaviate offers similarity or vector based search in three ways. You can do it with text, vector or object. Similarily, `WeaviateRecord` comes with three methods.

- [near_text](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FNearText:near_text)
- [near_vector](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FNearVector:near_vector)
- [near_object](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FNearObject:near_object)

It is important to specify the threshold distance whenever you are using similarity search. Otherwise, you search will not be much relevant. You can do it by either passing `distance` parameter to the search or by setting the default value for all three searches in the config.

### QnA Transformers - `#ask` and `#answer`

If you have enabled `QnA Transformers` in your weaviate database, you can use the [#ask](https://rubydoc.info/gems/weaviate_record/WeaviateRecord%2FQueries%2FAsk:ask) method and get an `answer` attribute like this:

```ruby
Article.create(content: "I'm Barney Stinson. You can call me Legendary")

Article.ask('who is he').select(_additional: { answer: :result }).first.answer
# => {"result"=>"barney stinson"}
```

And just like that, you can easily brings the `RAG` to you Ruby application.

### Summarizer - `#summary`

If you have enabled `Sum Transformers` in your weaviate database, you can summarize the attribute holding the large text like movie review or article summary. Summarizer don't have its own method for now. However, you can call it by doing little work around on `#select` method.

```ruby
content = <<~TEXT
  Ruby on Rails (simplified as Rails) is a server-side web application framework written in Ruby under the MIT License.
  Rails is a model–view–controller (MVC) framework, providing default structures for a database, a web service, and web pages.
  It encourages and facilitates the use of web standards such as JSON or XML for data transfer and HTML, CSS and JavaScript for user interfacing.
  In addition to MVC, Rails emphasizes the use of other well-known software engineering patterns and paradigms, including convention over configuration (CoC), don't repeat yourself (DRY), and the active record pattern.
TEXT
article = Article.create(content: content)

results = Article.where(id: article.id)
                 .select(_additional: 'summary(properties: ["content"]) { result }')
                 .first.summary

puts results
```

Output:

```ruby
[{"result"=>
   "Rails is a server-side web application framework written in Ruby under the MIT License. It is a model–view–controller (MVC) framework, providing default structures for a database, a web service, and web pages. It encourages and facilitates the use of web standards such as HTML, CSS and JavaScript."}]
```

#### Limitations

`WeaviateRecord` is not yet fully featured ORM like `ActiveRecord`. It doesn't support association, DSL or way to write and handle migrations yet.

#### Support

Feel free to open an issue or PR if you notice any feature is missing or wrong. Happy coding 🎉
