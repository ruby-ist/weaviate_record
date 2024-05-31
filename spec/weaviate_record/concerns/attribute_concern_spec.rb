# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Concerns::AttributeConcern do
  let(:klass) do
    Class.new do
      include WeaviateRecord::MethodMissing
      include WeaviateRecord::Concerns::AttributeConcern

      def collection_name; end
    end
  end
  let(:instance) { klass.new }

  before do
    instance.instance_variable_set(:@attributes, {})
    instance.instance_variable_set(:@meta_attributes, {})
    instance.instance_variable_set(:@custom_selected, true)
  end

  describe '#check_attributes' do
    it 'raises an error if the attributes are invalid' do
      allow(instance).to receive(:list_of_valid_attributes).and_return(['valid_attribute'])
      expect do
        instance.send(:check_attributes, { 'invalid_attribute' => 'value' })
      end.to raise_error(WeaviateRecord::Errors::InvalidAttributeError)
    end

    it 'does not raise an error if the attributes are valid' do
      allow(instance).to receive(:list_of_valid_attributes).and_return(['valid_attribute'])
      expect do
        instance.send(:check_attributes, { 'valid_attribute' => 'value' })
      end.not_to raise_error
    end
  end

  describe '#merge_attributes' do
    before do
      instance.instance_variable_set(:@attributes, { 'type' => 'test' })
      allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content])
    end

    context 'when the attributes are invalid' do
      it 'raises an error' do
        expect do
          instance.send(:merge_attributes, { 'invalid_attribute' => 'value' })
        end.to raise_error(WeaviateRecord::Errors::InvalidAttributeError)
      end
    end

    context 'when the key is already in @attributes' do
      it 'overrides the key' do
        instance.send(:merge_attributes, { 'type' => 'new_test' })
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'new_test' })
      end
    end

    context 'when the key is not in @attributes' do
      it 'adds the key' do
        instance.send(:merge_attributes, { 'content' => 'This is test' })
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test', 'content' => 'This is test' })
      end
    end

    context 'when the key is a symbol' do
      it 'converts the key to a string' do
        instance.send(:merge_attributes, { 'content' => 'This is test' })
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test', 'content' => 'This is test' })
      end
    end
  end

  describe '#load_attributes' do
    context 'when the argument is empty' do
      it 'sets all attributes of collection to nil' do
        allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content tags])
        instance.send(:load_attributes, {})
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => nil, 'content' => nil, 'tags' => nil })
      end
    end

    context 'when the argument is not empty' do
      context 'when it is a queried record' do
        it 'only assigns the attributes that are present in the argument' do
          instance.instance_variable_set(:@custom_selected, true)
          instance.send(:load_attributes, { 'type' => 'test' })
          expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test' })
        end
      end

      context 'when it is not a queried record' do
        it 'assigns nil to keys that are not present in the argument' do
          allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content tags])
          instance.instance_variable_set(:@custom_selected, false)
          instance.send(:load_attributes, { 'type' => 'test' })
          expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test',
                                                                       'content' => nil, 'tags' => nil })
        end
      end

      it 'omits the _additional key' do
        instance.instance_variable_set(:@custom_selected, true)
        instance.send(:load_attributes, { 'type' => 'test', '_additional' => 'test' })
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test' })
      end
    end
  end

  describe '#create_attribute_writers' do
    it 'creates a writer method for each attribute' do
      allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content tags])
      instance.send(:create_attribute_writers)
      expect(instance.singleton_methods).to include(:type=, :content=, :tags=)
    end

    context 'with writer methods' do
      it 'assigns the value to the attributes instance variable' do
        allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content tags])
        instance.send(:create_attribute_writers)
        instance.type = 'test'
        instance.content = 'This is test'
        instance.tags = %w[tag1 tag2]
        expect(instance.instance_variable_get(:@attributes)).to eq({ 'type' => 'test', 'content' => 'This is test',
                                                                     'tags' => %w[tag1 tag2] })
      end
    end
  end

  describe '#create_attribute_readers' do
    it 'calls #handle_timestamp_attributes' do
      allow(instance).to receive(:list_of_valid_attributes).and_return([])
      expect(instance).to receive(:handle_timestamp_attributes)
      instance.send(:create_attribute_readers)
    end

    context 'with attributes instance variable' do
      before do
        instance.instance_variable_set(:@attributes, { 'type' => 'test', 'content' => 'This is test' })
        allow(instance).to receive(:list_of_valid_attributes).and_return(%w[type content tags])
      end

      context 'when it is a queried record' do
        before { instance.instance_variable_set(:@custom_selected, true) }

        it 'creates a reader method for only attributes in that' do
          instance.send(:create_attribute_readers)
          expect(instance.singleton_methods).to contain_exactly(:type, :content)
        end

        context 'with reader methods' do
          it 'returns the value of the key in attributes hash' do
            instance.send(:create_attribute_readers)
            expect(instance.content).to eq('This is test')
          end

          it 'does not read un queried attributes' do
            instance.send(:create_attribute_readers)
            allow(instance).to receive(:list_of_all_attributes).and_return(['tags'])
            expect do
              instance.tags
            end.to raise_error(WeaviateRecord::Errors::MissingAttributeError, 'missing attribute: tags')
          end
        end
      end

      context 'when it is not a queried record' do
        before { instance.instance_variable_set(:@custom_selected, false) }

        it 'creates a reader method for all attributes of collection' do
          instance.send(:create_attribute_readers)
          expect(instance.singleton_methods).to contain_exactly(:type, :content, :tags)
        end

        context 'with reader methods' do
          it 'returns the value of the key in attributes hash' do
            instance.send(:create_attribute_readers)
            expect(instance.content).to eq('This is test')
          end
        end
      end
    end

    context 'with additional instance variable' do
      before do
        allow(instance).to receive(:list_of_valid_attributes).and_return([])
        instance.instance_variable_set(:@meta_attributes, { 'id' => 123, 'distance' => 0.43,
                                                            'created_at' => DateTime.parse('2024-02-11') })
      end

      it 'creates a reader method for each key in additional hash' do
        instance.send(:create_attribute_readers)
        expect(instance.singleton_methods).to include(:id, :distance, :created_at)
      end

      context 'with reader methods' do
        it 'returns the value of the key in additional hash' do
          instance.send(:create_attribute_readers)
          expect(instance.distance).to eq(0.43)
        end
      end
    end
  end

  describe '#handle_timestamp_attributes' do
    context 'when the additional hash contains creationTimeUnix' do
      it 'calls replace_timestamp_attribute' do
        instance.instance_variable_set(:@meta_attributes, { 'creationTimeUnix' => '1644547200000' })
        expect(instance).to receive(:replace_timestamp_attribute).with('creationTimeUnix')
        instance.send(:handle_timestamp_attributes)
      end
    end

    context 'when the additional hash contains lastUpdateTimeUnix' do
      it 'calls replace_timestamp_attribute' do
        instance.instance_variable_set(:@meta_attributes, { 'lastUpdateTimeUnix' => '1644547200000' })
        expect(instance).to receive(:replace_timestamp_attribute).with('lastUpdateTimeUnix')
        instance.send(:handle_timestamp_attributes)
      end
    end
  end

  describe '#replace_timestamp_attribute' do
    it 'replaces the timestamp keys with the mapped key' do
      instance.instance_variable_set(:@meta_attributes, { 'creationTimeUnix' => '1644547200000',
                                                          'lastUpdateTimeUnix' => '1644547200000' })
      mapped_keys = [WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key('creationTimeUnix'),
                     WeaviateRecord::Constants::SPECIAL_ATTRIBUTE_MAPPINGS.key('lastUpdateTimeUnix')]
      instance.send(:replace_timestamp_attribute, 'creationTimeUnix')
      instance.send(:replace_timestamp_attribute, 'lastUpdateTimeUnix')
      expect(instance.instance_variable_get(:@meta_attributes).keys).to match_array(mapped_keys)
    end

    it 'converts the value to a DateTime object' do
      instance.instance_variable_set(:@meta_attributes, { 'creationTimeUnix' => '1644547200000' })
      instance.send(:replace_timestamp_attribute, 'creationTimeUnix')
      expect(instance.instance_variable_get(:@meta_attributes)['created_at'])
        .to eq(DateTime.parse('2022-02-11 02:40:00'))
    end

    it 'deletes the original key' do
      instance.instance_variable_set(:@meta_attributes, { 'creationTimeUnix' => '1644547200000',
                                                          'lastUpdateTimeUnix' => '1644547200000' })
      instance.send(:replace_timestamp_attribute, 'creationTimeUnix')
      instance.send(:replace_timestamp_attribute, 'lastUpdateTimeUnix')
      expect(instance.instance_variable_get(:@meta_attributes).keys).not_to include('creationTimeUnix',
                                                                                    'lastUpdateTimeUnix')
    end
  end
end
