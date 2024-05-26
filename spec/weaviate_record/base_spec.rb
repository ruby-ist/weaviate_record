# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Base do
  it 'delegates query methods to Weaviate::Relation' do
    %i[select limit offset near_text bm25 where order].each do |method|
      expect_any_instance_of(WeaviateRecord::Relation).to receive(method)
      described_class.public_send(method, '1')
    end
  end

  it 'delegates :all method to Weaviate::Relation' do
    expect_any_instance_of(WeaviateRecord::Relation).to receive(:all)
    described_class.all
  end

  describe '#new' do
    context 'with empty initialization' do
      let(:document) { Article.new }

      it 'creates setter functions for each attributes' do
        attributes = WeaviateTestHelper.send(:properties_list, Article).map! { :"#{_1}=" }
        expect(attributes - document.singleton_methods).to be_empty
      end

      it 'creates getter methods for all fields' do
        attributes = WeaviateTestHelper.send(:properties_list, Article).map!(&:to_sym)
        attributes.each do |attribute|
          expect(document.public_send(attribute)).to be_nil
        end
      end

      it 'comes with id as nil' do
        expect(document.id).to be_nil
      end

      it 'comes with created_at as nil' do
        expect(document.created_at).to be_nil
      end

      it 'comes with updated_at as nil' do
        expect(document.updated_at).to be_nil
      end
    end

    context 'when initialized with attributes' do
      it 'can take attributes as hash' do
        document = Article.new({ title: 'test_document', type: 'test' })
        expect([document.title, document.type]).to match_array(%w[test_document test])
      end

      it 'can take attributes as keyword' do
        document = Article.new(title: 'test_document', content: 'test')
        expect([document.title, document.content]).to match_array(%w[test_document test])
      end

      it 'creates setter & setter functions for all attributes' do
        document = Article.new(title: 'test_document', type: 'test')
        attributes = WeaviateTestHelper.send(:properties_list, Article)
        attributes += attributes.map { "#{_1}=" }
        attributes.map!(&:to_sym)
        expect(document.singleton_methods).to include(*attributes)
      end

      it 'throws error if invalid attributes present' do
        fields = { 'type' => 'article', 'invalid_field' => '0' }
        expect { Document.new(**fields) }.to raise_error(Weaviate::Errors::InvalidAttributeError)
      end

      context 'when additional attributes are given' do
        let(:document) do
          Document.new(content: 'This is a test', type: 'test', tags: ['test'],
                       _additional: { id: 1354, vector: [23, 43, 54] })
        end

        it 'creates getter methods' do
          expect(document.vector).to eq([23, 43, 54])
        end

        it 'does not create setter methods' do
          expect { document.vector = [0, 0, 0] }.to raise_error(NoMethodError)
        end
      end
    end

    context 'when record is created with queried true' do
      let(:document) { Document.new(queried: true, content: 'This is a test', type: 'Test') }

      it 'only creates getter methods for provided attributes' do
        expect(document.singleton_methods).to include(:content, :type)
      end

      it 'doesn not create getter methods unprovided attributes' do
        expect(document.singleton_methods).not_to include(:categories)
      end

      it 'throws error for un-queried attributes' do
        expect { document.tags }.to raise_error(Weaviate::Errors::MissingAttributeError)
      end
    end
  end

  describe '#create' do
    it 'creates new record and returns id' do
      document = Article.create(content: 'Hello', type: 'test')
      expect(document.id).not_to be_nil
      document.destroy
    end

    context 'when save fails' do
      it 'returns a shell record' do
        allow_any_instance_of(Article).to receive(:save).and_return(false)
        document = Article.create(content: 'Hello', type: 'test')
        expect(document.id).to be_nil
        document.destroy
      end
    end
  end

  describe '#find' do
    context 'when id is valid' do
      let!(:document) { Article.create(content: 'Hello, how are you?', type: 'test') }
      let(:id) { document.id }

      after { document.destroy }

      it 'returns document for valid id' do
        expect(Article.find(id)).to be_instance_of(Article)
      end

      it 'raises error for destroyed id' do
        document.destroy
        expect do
          Article.find(id)
        end.to raise_error(Weaviate::Errors::RecordNotFoundError, "Couldn't find Document with id=#{id}")
      end

      context 'when record is returned' do
        it 'responds to additional attributes' do
          expect(Article.find(id)).to respond_to(:id, :created_at, :updated_at)
        end

        it 'responds to collection attributes' do
          expect(Article.find(id)).to respond_to(*WeaviateTestHelper.send(:properties_list, Article))
        end
      end
    end

    context 'when id is invalid or not uuid' do
      it 'raises error' do
        expect do
          Article.find(23)
        end.to raise_error(Weaviate::Errors::ServerError, 'id in path must be of type uuid: "23"')
      end
    end
  end

  describe '#count' do
    let!(:documents) do
      10.times.map do
        Article.create
      end
    end

    after { documents.each(&:destroy) }

    it 'returns the count of records' do
      expect(Article.count).to be(10)
    end

    it 'raises error when unable to get the count' do
      allow_any_instance_of(Weaviate::Query).to receive(:aggs).and_return('')
      expect do
        Article.count
      end.to raise_error(Weaviate::Errors::ServerError, 'unable to get the count for Article collection.')
    end
  end

  describe '#save' do
    let(:document) { Article.new }

    it 'calls #validate_and_save' do
      expect(document).to receive(:validate_and_save)
      document.save
    end

    context 'when #validate_and_save returns false' do
      before { allow(document).to receive(:validate_and_save).and_return(false) }

      it 'returns false' do
        expect(document.save).to be(false)
      end
    end

    context 'when #validate_and_save returns result' do
      context 'when result has error' do
        before { allow(document).to receive(:validate_and_save).and_return({ 'error' => 'testing_error' }) }

        it 'returns false' do
          expect(document.save).to be(false)
        end

        it 'adds error to base' do
          document.save
          expect(document.errors[:base]).to include('testing_error')
        end
      end

      context 'when result is successful' do
        before do
          result = { 'id' => '1234', 'creationTimeUnix' => 1_000_000, 'lastUpdateTimeUnix' => 1_000_000 }
          allow(document).to receive(:validate_and_save).and_return(result)
        end

        it 'updates id attribute' do
          document.save
          expect(document.id).to eq('1234')
        end

        it 'updates created_at attribute' do
          document.save
          expect(document.created_at).to eq(DateTime.strptime(1_000_000.to_s, '%Q'))
        end

        it 'updates updated_at attribute' do
          document.save
          expect(document.updated_at).to eq(DateTime.strptime(1_000_000.to_s, '%Q'))
        end

        it 'returns true' do
          expect(document.save).to be(true)
        end
      end
    end
  end

  describe '#update' do
    let(:document) { Article.create(content: 'This is a test', type: 'test') }

    after { document.destroy }

    it 'calls #update_validation_check' do
      expect(document).to receive(:update_validation_check)
      document.update(content: 'This is test')
    end

    it 'calls #merge_attributes' do
      expect(document).to receive(:merge_attributes)
      document.update(content: 'This is test')
    end

    context 'when called on new record' do
      it 'raises error' do
        document = Article.new
        expect { document.update(content: 'This is test') }.to raise_error(Weaviate::Errors::MissingIdError,
                                                                           'the record doesn\'t have an id')
      end
    end

    context 'when called without any arguments' do
      it 'raises error' do
        expect { document.update }.to raise_error(ArgumentError, 'update action requires minimum one attribute')
      end
    end

    context 'when meta attributes is given' do
      it 'raises error' do
        expect do
          document.update(_additional: { vector: [1, 4, 5] })
        end.to raise_error(Weaviate::Errors::MetaAttributeError, 'cannot update meta attributes')
      end
    end

    context 'when all attributes are valid' do
      context 'when the values are not valid' do
        before { allow(document).to receive(:valid?).and_return(false) }

        it 'returns false' do
          expect(document.update(content: 234)).to be(false)
        end
      end

      context 'when the values are valid' do
        it 'calls #update_call' do
          expect(document).to receive(:update_call)
            .with(document.id, document.instance_variable_get(:@attributes))
            .and_call_original
          document.update(content: 'updated content!')
        end

        context 'when not updated in weaviate' do
          it 'returns false' do
            expect(document.update(content: 234)).to be(false)
          end

          it 'adds weaviate error to base' do
            document.update(content: 234)
            expect(document.errors[:base]).not_to be_empty
          end
        end

        context 'when error happens in weaviate' do
          it 'raises error' do
            allow_any_instance_of(Weaviate::Objects).to receive(:update).and_return('')
            expect do
              document.update(content: 'updated content!')
            end.to raise_error(Weaviate::Errors::ServerError, 'unable to update the weaviate record')
          end
        end

        context 'when updated successfully' do
          it 'returns true' do
            expect(document.update(content: 'updated content!')).to be(true)
          end
        end
      end
    end

    context 'when performed on custom queried record' do
      let!(:document) { Article.create(content: 'this is test', type: 'test') }
      let(:record) { Article.select(:content, :type, _additional: :id).all.last }

      after { document.destroy }

      it 'raises error' do
        expect do
          record.update(content: 'this is another test')
        end.to raise_error(Weaviate::Errors::CustomQueriedRecordError,
                           'cannot perform update action on custom queried record')
      end
    end
  end

  describe '#destroy' do
    it 'calls #validate_record_for_destroy' do
      document = Article.create(content: 'Hello', type: 'test')
      expect(document).to receive(:validate_record_for_destroy)
      document.destroy
    end

    context 'when #validate_record_for_destroy returns false' do
      it 'returns self' do
        document = Article.create(content: 'Hello', type: 'test')
        allow(document).to receive(:validate_record_for_destroy).and_return(false)
        expect(document.destroy).to be(document)
      end
    end

    context 'when the record is valid for destroy action' do
      it 'calls #delete_call' do
        document = Article.create(content: 'Hello', type: 'test')
        expect(document).to receive(:delete_call).and_call_original
        document.destroy
      end

      context 'when delete_call returns true' do
        it 'returns self' do
          document = Article.create(content: 'Hello', type: 'test')
          expect(document.destroy).to be(document)
        end

        it 'freeze the record' do
          document = Article.create(content: 'Hello', type: 'test')
          document.destroy
          expect(document).to be_frozen
        end
      end

      context 'when delete_call returns error' do
        let(:document) { Article.create(content: 'Hello', type: 'test') }

        before { allow(document).to receive(:delete_call).and_return({ 'error' => 'testing_error' }) }
        after { Article.all.each(&:destroy) }

        it 'returns false' do
          expect(document.destroy).to be(false)
        end

        it 'adds error to base' do
          document.destroy
          expect(document.errors[:base]).to include('testing_error')
        end
      end
    end
  end

  describe '#persisted?' do
    it 'returns true for persisted record' do
      document = Article.create(content: 'Hello', type: 'test')
      expect(document.persisted?).to be(true)
      document.destroy
    end

    it 'returns false for new record' do
      document = Article.new
      expect(document.persisted?).to be(false)
    end

    it 'raises error for destroyed record' do
      created_document = Article.create(content: 'Hello', type: 'test')
      queried_document = Article.select(:content, :type).first
      expect do
        queried_document.persisted?
      end.to raise_error(Weaviate::Errors::CustomQueriedRecordError,
                         'cannot perform persisted? action on custom queried record')
      created_document.destroy
    end
  end
end
