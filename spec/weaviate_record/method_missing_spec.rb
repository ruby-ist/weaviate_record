# frozen_string_literal: true

require 'spec_helper'

describe WeaviateRecord::MethodMissing do
  let(:klass) do
    Class.new do
      include WeaviateRecord::MethodMissing

      def existing_method; end
      def collection_name; end
    end
  end
  let(:instance) { klass.new }
  let(:schema) { WeaviateRecord::Schema.send(:new, {}) }

  before do
    allow(instance).to receive(:collection_name).and_return(klass)
    allow(WeaviateRecord::Schema).to receive(:find_collection).with(klass).and_return(schema)
  end

  describe '#method_missing' do
    context 'when a method name is one of attribute name' do
      it 'raises a Weaviate::MissingAttributeError' do
        allow(schema).to receive(:attributes_list).and_return(%w[type content])
        expect do
          instance.type
        end.to raise_error(WeaviateRecord::Errors::MissingAttributeError, 'missing attribute: type')
      end
    end

    context 'when a method name is one of additional attribute name' do
      it 'raises a Weaviate::MissingAttributeError' do
        allow(schema).to receive(:attributes_list).and_return([])
        expect do
          instance.vector
        end.to raise_error(WeaviateRecord::Errors::MissingAttributeError, 'missing attribute: vector')
      end
    end

    context 'when a non-attribute method is called' do
      it 'calls super' do
        allow(schema).to receive(:attributes_list).and_return([])
        expect { instance.foo }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#respond_to_missing?' do
    context 'when it is a missing attribute' do
      it 'returns false' do
        allow(schema).to receive(:attributes_list).and_return(%w[type content])
        expect(instance).not_to respond_to(:type)
      end
    end

    context 'when it ia a meta attribute' do
      it 'returns false' do
        allow(schema).to receive(:attributes_list).and_return([])
        expect(instance).not_to respond_to(:vector)
      end
    end

    context 'when it is not a valid attribute' do
      it 'returns false' do
        allow(schema).to receive(:attributes_list).and_return([])
        expect(instance).not_to respond_to(:foo)
      end
    end

    context 'when it is an existing method' do
      it 'returns true' do
        expect(instance).to respond_to(:existing_method)
      end
    end
  end
end
