# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Base do
  let(:schema) { WeaviateRecord::Schema.find_collection(Article) }
  let(:connection) { WeaviateRecord::Connection.new('Article') }

  it 'delegates query methods to WeaviateRecord::Relation' do
    %i[select limit offset near_text bm25 where order].each do |method|
      expect_any_instance_of(WeaviateRecord::Relation).to receive(method)
      described_class.public_send(method, '1')
    end
  end

  it 'delegates :all method to WeaviateRecord::Relation' do
    expect_any_instance_of(WeaviateRecord::Relation).to receive(:all)
    described_class.all
  end

  describe '#new' do
    context 'with empty initialization' do
      let(:article) { Article.new }

      it 'creates setter functions for each attributes' do
        attributes = schema.attributes_list.map! { :"#{_1}=" }
        expect(attributes - article.singleton_methods).to be_empty
      end

      it 'creates getter methods for all fields' do
        attributes = schema.attributes_list.map!(&:to_sym)
        attributes.each do |attribute|
          expect(article.public_send(attribute)).to be_nil
        end
      end

      it 'comes with id as nil' do
        expect(article.id).to be_nil
      end

      it 'comes with created_at as nil' do
        expect(article.created_at).to be_nil
      end

      it 'comes with updated_at as nil' do
        expect(article.updated_at).to be_nil
      end
    end

    context 'when initialized with attributes' do
      it 'can take attributes as hash' do
        article = Article.new({ title: 'test_article', author: 'srira' })
        expect([article.title, article.author]).to match_array(%w[test_article srira])
      end

      it 'can take attributes as keyword' do
        article = Article.new(title: 'test_article', content: 'test')
        expect([article.title, article.content]).to match_array(%w[test_article test])
      end

      it 'creates setter & setter functions for all attributes' do
        article = Article.new(title: 'test_article', content: 'srira')
        attributes = schema.attributes_list
        attributes += attributes.map { "#{_1}=" }
        attributes.map!(&:to_sym)
        expect(article.singleton_methods).to include(*attributes)
      end

      it 'throws error if invalid attributes present' do
        fields = { 'title' => 'article', 'invalid_field' => '0' }
        expect { Article.new(**fields) }.to raise_error(WeaviateRecord::Errors::InvalidAttributeError)
      end

      context 'when additional attributes are given' do
        let(:article) do
          Article.new(content: 'This is a test', author: 'srira', categories: ['test'],
                      _additional: { id: 1354, vector: [23, 43, 54] })
        end

        it 'creates getter methods' do
          expect(article.vector).to eq([23, 43, 54])
        end

        it 'does not create setter methods' do
          expect { article.vector = [0, 0, 0] }.to raise_error(NoMethodError)
        end
      end
    end

    context 'when record is created with queried true' do
      let(:article) { Article.new(custom_selected: true, content: 'This is a test', author: 'srira') }

      it 'only creates getter methods for provided attributes' do
        expect(article.singleton_methods).to include(:content, :author)
      end

      it 'doesn not create getter methods unprovided attributes' do
        expect(article.singleton_methods).not_to include(:categories)
      end

      it 'throws error for un-queried attributes' do
        expect { article.categories }.to raise_error(WeaviateRecord::Errors::MissingAttributeError)
      end
    end
  end

  describe '#create' do
    it 'creates new record and returns id' do
      article = Article.create(content: 'Hello', author: 'srira')
      expect(article.id).not_to be_nil
      article.destroy
    end

    context 'when save fails' do
      it 'returns a shell record' do
        allow_any_instance_of(Article).to receive(:save).and_return(false)
        article = Article.create(content: 'Hello', author: 'srira')
        expect(article.id).to be_nil
        article.destroy
      end
    end
  end

  describe '#find' do
    context 'when id is valid' do
      let!(:article) { Article.create(content: 'Hello, how are you?', author: 'srira') }
      let(:id) { article.id }

      after { article.destroy }

      it 'returns article for valid id' do
        expect(Article.find(id)).to be_instance_of(Article)
      end

      it 'raises error for destroyed id' do
        article.destroy
        expect do
          Article.find(id)
        end.to raise_error(WeaviateRecord::Errors::RecordNotFoundError, "Couldn't find record with id=#{id}")
      end

      context 'when record is returned' do
        it 'responds to additional attributes' do
          expect(Article.find(id)).to respond_to(:id, :created_at, :updated_at)
        end

        it 'responds to collection attributes' do
          expect(Article.find(id)).to respond_to(*schema.attributes_list)
        end
      end
    end

    context 'when id is invalid or not uuid' do
      it 'raises error' do
        expect do
          Article.find(23)
        end.to raise_error(WeaviateRecord::Errors::ServerError, 'id in path must be of type uuid: "23"')
      end
    end
  end

  describe '#count' do
    let!(:articles) do
      10.times.map do
        Article.create
      end
    end

    after { articles.each(&:destroy) }

    it 'returns the count of records' do
      expect(Article.count).to be(10)
    end

    it 'raises error when unable to get the count' do
      allow_any_instance_of(Weaviate::Query).to receive(:aggs).and_return('')
      expect do
        Article.count
      end.to raise_error(WeaviateRecord::Errors::ServerError, 'unable to get the count for Article collection.')
    end
  end

  describe '#save' do
    let(:article) { Article.new }

    it 'calls #validate_and_save' do
      expect(article).to receive(:validate_and_save)
      article.save
    end

    context 'when #validate_and_save returns false' do
      before { allow(article).to receive(:validate_and_save).and_return(false) }

      it 'returns false' do
        expect(article.save).to be(false)
      end
    end

    context 'when #validate_and_save returns result' do
      context 'when result has error' do
        before { allow(article).to receive(:validate_and_save).and_return({ 'error' => 'testing_error' }) }

        it 'returns false' do
          expect(article.save).to be(false)
        end

        it 'adds error to base' do
          article.save
          expect(article.errors[:base]).to include('testing_error')
        end
      end

      context 'when result is successful' do
        before do
          result = { 'id' => '1234', 'creationTimeUnix' => 1_000_000, 'lastUpdateTimeUnix' => 1_000_000 }
          allow(article).to receive(:validate_and_save).and_return(result)
        end

        it 'updates id attribute' do
          article.save
          expect(article.id).to eq('1234')
        end

        it 'updates created_at attribute' do
          article.save
          expect(article.created_at).to eq(DateTime.strptime(1_000_000.to_s, '%Q'))
        end

        it 'updates updated_at attribute' do
          article.save
          expect(article.updated_at).to eq(DateTime.strptime(1_000_000.to_s, '%Q'))
        end

        it 'returns true' do
          expect(article.save).to be(true)
        end
      end
    end
  end

  describe '#update' do
    let(:article) { Article.create(content: 'This is a test', author: 'srira') }

    before { article.instance_variable_set('@connection', connection) }

    it 'calls #validate_record_for_update' do
      expect(article).to receive(:validate_record_for_update).with({ 'content' => 'This is test' })
      article.update(content: 'This is test')
    end

    it 'calls #merge_attributes' do
      allow(article).to receive(:merge_attributes).with(any_args).and_call_original
      article.update(content: 'This is test')
      expect(article).to have_received(:merge_attributes).with({ 'content' => 'This is test' })
    end

    context 'when called on new record' do
      it 'raises error' do
        article = Article.new
        expect { article.update(content: 'This is test') }.to raise_error(WeaviateRecord::Errors::MissingIdError,
                                                                          'the record doesn\'t have an id')
      end
    end

    context 'when called without any arguments' do
      it 'raises error' do
        expect { article.update }.to raise_error(ArgumentError, 'update action requires minimum one attribute')
      end
    end

    context 'when meta attributes is given' do
      it 'raises error' do
        expect do
          article.update(_additional: { vector: [1, 4, 5] })
        end.to raise_error(WeaviateRecord::Errors::MetaAttributeError, 'cannot update meta attributes')
      end
    end

    context 'when all attributes are valid' do
      context 'when the values are not valid' do
        it 'returns false' do
          expect(article.update(content: 234)).to be(false)
        end
      end

      context 'when the values are valid' do
        it 'calls #update_call' do
          expect(connection).to receive(:update_call)
            .with(article.id, article.instance_variable_get(:@attributes))
            .and_call_original
          article.update(content: 'updated content!')
        end

        context 'when not updated in weaviate' do
          it 'returns false' do
            expect(article.update(content: 234)).to be(false)
          end

          it 'adds weaviate error to base' do
            article.update(content: 234)
            expect(article.errors[:base]).not_to be_empty
          end
        end

        context 'when error happens in weaviate' do
          it 'raises error' do
            allow_any_instance_of(Weaviate::Objects).to receive(:update).and_return('')
            expect do
              article.update(content: 'updated content!')
            end.to raise_error(WeaviateRecord::Errors::ServerError, 'unable to update the weaviate record')
          end
        end

        context 'when updated successfully' do
          it 'returns true' do
            expect(article.update(content: 'updated content!')).to be(true)
          end
        end
      end
    end

    context 'when performed on custom queried record' do
      let!(:article) { Article.create(content: 'this is test', author: 'srira') }
      let(:record) { Article.select(:content, :author, _additional: :id).all.last }

      after { article.destroy }

      it 'raises error' do
        expect do
          record.update(content: 'this is another test')
        end.to raise_error(WeaviateRecord::Errors::CustomQueriedRecordError,
                           'cannot perform update action on custom selected record')
      end
    end
  end

  describe '#destroy' do
    it 'calls #validate_record_for_destroy' do
      article = Article.create(content: 'Hello', author: 'srira')
      expect(article).to receive(:validate_record_for_destroy)
      article.destroy
    end

    context 'when #validate_record_for_destroy returns false' do
      it 'returns self' do
        article = Article.create(content: 'Hello', author: 'srira')
        allow(article).to receive(:validate_record_for_destroy).and_return(false)
        expect(article.destroy).to be(article)
      end
    end

    context 'when the record is valid for destroy action' do
      it 'calls #delete_call' do
        article = Article.create(content: 'Hello', author: 'srira')
        article.instance_variable_set('@connection', connection)
        expect(connection).to receive(:delete_call).and_call_original
        article.destroy
      end

      context 'when delete_call returns true' do
        it 'returns self' do
          article = Article.create(content: 'Hello', author: 'srira')
          expect(article.destroy).to be(article)
        end

        it 'freeze the record' do
          article = Article.create(content: 'Hello', author: 'srira')
          article.destroy
          expect(article).to be_frozen
        end
      end

      context 'when delete_call returns error' do
        let(:article) { Article.create(content: 'Hello', author: 'srira') }

        before do
          article.instance_variable_set('@connection', connection)
          allow(connection).to receive(:delete_call).and_return({ 'error' => 'testing_error' })
        end

        after { Article.all.each(&:destroy) }

        it 'returns false' do
          expect(article.destroy).to be(false)
        end

        it 'adds error to base' do
          article.destroy
          expect(article.errors[:base]).to include('testing_error')
        end
      end
    end
  end

  describe '#persisted?' do
    it 'returns true for persisted record' do
      article = Article.create(content: 'Hello', author: 'srira')
      expect(article.persisted?).to be(true)
      article.destroy
    end

    it 'returns false for new record' do
      article = Article.new
      expect(article.persisted?).to be(false)
    end

    it 'raises error for destroyed record' do
      created_article = Article.create(content: 'Hello', author: 'srira')
      queried_article = Article.select(:content, :author).first
      expect do
        queried_article.persisted?
      end.to raise_error(WeaviateRecord::Errors::CustomQueriedRecordError,
                         'cannot perform persisted? action on custom queried record')
      created_article.destroy
    end
  end
end
