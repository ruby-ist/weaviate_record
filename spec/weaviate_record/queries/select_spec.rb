# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Select do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Select
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  before do
    instance.instance_variable_set(:@select_options, { attributes: [], nested_attributes: {} })
    described_class.private_instance_methods.each do |method|
      allow(instance).to receive(method).with(any_args).and_call_original
    end
  end

  describe '#select' do
    it 'set loaded to false' do
      instance.select(:name)
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.select(:name)).to eq(instance)
    end

    context 'when normal argument is passed' do
      context 'when argument is not present in attributes' do
        it 'adds argument to attributes' do
          instance.select(:name)
          expect(instance.instance_variable_get(:@select_options)[:attributes]).to eq(['name'])
        end
      end

      context 'when argument is already present in attributes' do
        it 'does not add argument to attributes' do
          instance.instance_variable_set(:@select_options, { attributes: ['name'], nested_attributes: {} })
          instance.select(:name)
          expect(instance.instance_variable_get(:@select_options)[:attributes]).to eq(['name'])
        end
      end
    end

    context 'when keyword argument is passed' do
      context 'when argument is not present in nested_attributes' do
        it 'adds argument to nested_attributes' do
          instance.select(_additional: :id)
          expect(instance.instance_variable_get(:@select_options)[:nested_attributes]).to eq({ _additional: :id })
        end
      end

      context 'when argument is already present in nested_attributes' do
        it 'does not add argument to nested_attributes' do
          instance.instance_variable_set(:@select_options,
                                         { attributes: [], nested_attributes: { _additional: :id } })
          instance.select(_additional: %i[id vector])
          expect(instance
                   .instance_variable_get(:@select_options)[:nested_attributes]).to eq({ _additional: %i[id vector] })
        end
      end
    end

    # context 'on queries' do
    #   let!(:documents) do
    #     [DocumentTest.create(type: 'test', content: 'This is a test', title: 'test document')]
    #   end
    #   after { documents.each(&:destroy) }

    #   it 'only selects the specified attributes from collection' do
    #     DocumentTest.select(:type, :content).each do |document|
    #       expect { document.title }.to raise_error(Weaviate::Errors::MissingAttributeError)
    #     end
    #   end

    #   it 'can query _additional meta attributes' do
    #     DocumentTest.select(_additional: %i[id distance updated_at]).each do |document|
    #       expect(document).to respond_to(:id, :distance, :updated_at)
    #     end
    #   end
    # end
  end

  describe '#combined_select_attributes' do
    it 'calls format_array_attribute with attributes' do
      instance.instance_variable_set(:@select_options, { attributes: %i[type content], nested_attributes: {} })
      instance.send(:combined_select_attributes)
      expect(instance).to have_received(:format_array_attribute).with(%i[type content])
    end

    context 'when nested attribute present' do
      it 'calls format_nested_attribute with nested_attributes' do
        instance.instance_variable_set(:@select_options, { attributes: [],
                                                           nested_attributes: { _additional: %i[id vector] } })
        instance.send(:combined_select_attributes)
        expect(instance).to have_received(:format_nested_attribute)
          .with({ _additional: %i[id vector] })
      end
    end

    context 'when nested_attributes are not present' do
      it 'does not calls format_nested_attribute' do
        instance.instance_variable_set(:@select_options, { attributes: %i[type content], nested_attributes: {} })
        instance.send(:combined_select_attributes)
        expect(instance).not_to have_received(:format_nested_attribute)
      end
    end

    it 'returns string with attributes and nested_attributes' do
      instance.instance_variable_set(:@select_options, { attributes: %i[type content],
                                                         nested_attributes: { _additional: %i[id vector] } })
      expect(instance.send(:combined_select_attributes)).to eq('type content _additional { id vector }')
    end
  end

  describe '#create_or_process_select_fields' do
    context 'when custom is true' do
      it 'replaces special attributes with their mappings' do
        attributes = 'type content _additional { created_at updated_at feature_projection }'
        mapped_attributes = 'type content _additional { creationTimeUnix lastUpdateTimeUnix featureProjection }'
        expect(instance.send(:create_or_process_select_attributes, true, attributes)).to eq(mapped_attributes)
      end
    end

    context 'when custom is false' do
      before do
        instance.instance_variable_set(:@klass, 'Document')
        document_schema = WeaviateRecord::Schema.send(:new, {})
        allow(WeaviateRecord::Schema).to receive(:find_collection).with('Document').and_return(document_schema)
        allow(document_schema).to receive(:attributes_list).and_return(%w[type content title])
      end

      it 'returns properties list joined with _additional' do
        expect(instance.send(:create_or_process_select_attributes, false,
                             '')).to eq('type content title _additional { id creationTimeUnix lastUpdateTimeUnix }')
      end
    end
  end

  describe '#format_array_attribute' do
    context 'when the element is string or symbol' do
      it 'returns string with elements separated by space' do
        expect(instance.send(:format_array_attribute, ['type', 'content', :title])).to eq('type content title')
      end
    end

    context 'when the element is an Array' do
      it 'calls itself with nested array' do
        instance.send(:format_array_attribute, ['type', ['content', :title]])
        [['type', ['content', :title]], ['content', :title]].each do |level|
          expect(instance).to have_received(:format_array_attribute).with(level)
        end
      end
    end

    context 'when the element is a Hash' do
      it 'calls format_nested_attribute' do
        instance.send(:format_array_attribute, ['type', { _additional: :id }])
        expect(instance).to have_received(:format_nested_attribute).with({ _additional: :id })
      end
    end

    context 'when the element is any other type' do
      it 'raises ArgumentError' do
        expect { instance.send(:format_array_attribute, [1, 2, 3]) }.to raise_error(TypeError)
      end
    end
  end

  describe '#format_nested_attribute' do
    context 'when the value is string or symbol' do
      it 'returns string with value enclosed by curly braces' do
        expect(instance.send(:format_nested_attribute, { _additional: :id })).to eq('_additional { id }')
      end
    end

    context 'when the value is an Array' do
      it 'calls format_array_attribute' do
        instance.send(:format_nested_attribute, { _additional: %i[id vector distance] })
        expect(instance).to have_received(:format_array_attribute).with(%i[id vector distance])
      end
    end

    context 'when the value is a Hash' do
      it 'calls itself with nested hash' do
        instance.send(:format_nested_attribute, { _additional: { featureProjection: :vector } })
        [{ _additional: { featureProjection: :vector } },
         { featureProjection: :vector }].each do |level|
          expect(instance).to have_received(:format_nested_attribute).with(level)
        end
      end
    end

    context 'when the value is any other type' do
      it 'raises ArgumentError' do
        expect { instance.send(:format_nested_attribute, { _additional: 1 }) }.to raise_error(TypeError)
      end
    end
  end
end
