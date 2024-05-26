# frozen_string_literal: true

module WeaviateRecord
  # Schema module stores the schema of all Weaviate Collections
  class Schema
    def self.all_collections # rubocop:disable Metrics/MethodLength
      { classes: [{ class: 'Article',
                    description: 'An Informational article',
                    invertedIndexConfig: { bm25: { b: 0.75, k1: 1.2 },
                                           cleanupIntervalSeconds: 60,
                                           indexNullState: true,
                                           indexTimestamps: true,
                                           stopwords: { additions: nil, preset: 'en', removals: nil } },
                    moduleConfig: { 'text2vec-transformers': { poolingStrategy: 'masked_mean',
                                                               vectorizeClassName: true } },
                    multiTenancyConfig: { autoTenantCreation: false, enabled: false },
                    properties: [{ dataType: ['text'],
                                   description: 'Title of the article',
                                   indexFilterable: true,
                                   indexSearchable: true,
                                   moduleConfig: { 'text2vec-transformers': { skip: false,
                                                                              vectorizePropertyName: false } },
                                   name: 'title',
                                   tokenization: 'word' },
                                 { dataType: ['text'],
                                   description: 'Author of the article',
                                   indexFilterable: true,
                                   indexSearchable: true,
                                   moduleConfig: { 'text2vec-transformers': { skip: false,
                                                                              vectorizePropertyName: false } },
                                   name: 'author',
                                   tokenization: 'word' },
                                 { dataType: ['text[]'],
                                   description: 'Categories the article belongs to',
                                   indexFilterable: true,
                                   indexSearchable: true,
                                   moduleConfig: { 'text2vec-transformers': { skip: false,
                                                                              vectorizePropertyName: false } },
                                   name: 'categories',
                                   tokenization: 'word' },
                                 { dataType: ['boolean'],
                                   description: 'States whether the article is verified or not',
                                   indexFilterable: true,
                                   indexSearchable: false,
                                   moduleConfig: { 'text2vec-transformers': { skip: false,
                                                                              vectorizePropertyName: false } },
                                   name: 'verified' },
                                 { dataType: ['text'],
                                   description: 'Content of the article',
                                   indexFilterable: true,
                                   indexSearchable: true,
                                   moduleConfig: { 'text2vec-transformers': { skip: false,
                                                                              vectorizePropertyName: false } },
                                   name: 'content',
                                   tokenization: 'word' }],
                    replicationConfig: { factor: 1 },
                    shardingConfig: { actualCount: 1,
                                      actualVirtualCount: 128,
                                      desiredCount: 1,
                                      desiredVirtualCount: 128,
                                      function: 'murmur3',
                                      key: '_id',
                                      strategy: 'hash',
                                      virtualPerPhysical: 128 },
                    vectorIndexConfig: { bq: { enabled: false },
                                         cleanupIntervalSeconds: 300,
                                         distance: 'cosine',
                                         dynamicEfFactor: 8,
                                         dynamicEfMax: 500,
                                         dynamicEfMin: 100,
                                         ef: -1,
                                         efConstruction: 128,
                                         flatSearchCutoff: 40_000,
                                         maxConnections: 64,
                                         pq: { bitCompression: false,
                                               centroids: 256,
                                               enabled: false,
                                               encoder: { distribution: 'log-normal', type: 'kmeans' },
                                               segments: 0,
                                               trainingLimit: 100_000 },
                                         skip: false,
                                         vectorCacheMaxObjects: 1_000_000_000_000 },
                    vectorIndexType: 'hnsw',
                    vectorizer: 'text2vec-transformers' }] }
    end
  end
end
