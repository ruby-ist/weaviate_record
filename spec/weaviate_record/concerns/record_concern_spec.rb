# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Concerns::RecordConcern do
  let(:klass) do
    Class.new do
      include ActiveModel::Validations
      include WeaviateRecord::Concerns::RecordConcern
    end
  end
  let(:instance) { klass.new }

  before do
    WeaviateRecord::Concerns::AttributeHandlers.private_instance_methods.each do |method|
      allow(instance).to receive(method).with(any_args)
    end
  end

  describe '#collection_name' do
    it 'returns the class name' do
      expect(instance.collection_name).to eql(klass.to_s)
    end
  end

  describe '#validate_record_for_update' do
    before { instance.instance_variable_set(:@meta_attributes, { 'id' => 123 }) }

    it 'raises MissingIdError if id is nil' do
      instance.instance_variable_set(:@meta_attributes, { 'id' => nil })
      expect do
        instance.send(:validate_record_for_update, { type: 'test' })
      end.to raise_error(WeaviateRecord::Errors::MissingIdError, 'the record doesn\'t have an id')
    end

    it 'raises CustomQueriedRecordError if it is a queried record' do
      instance.instance_variable_set(:@custom_selected, true)
      expect do
        instance.send(:validate_record_for_update, { type: 'test' })
      end.to raise_error(WeaviateRecord::Errors::CustomQueriedRecordError, 'cannot perform update action on ' \
                                                                           'custom selected record')
    end

    it 'calls #check_attributes' do
      expect(instance).to receive(:check_attributes).with({ type: 'test' })
      instance.send(:validate_record_for_update, { type: 'test' })
    end

    it 'raises MetaAttributeError if _additional string key is present' do
      expect do
        instance.send(:validate_record_for_update,
                      { '_additional' => 'test' })
      end.to raise_error(WeaviateRecord::Errors::MetaAttributeError, 'cannot update meta attributes')
    end

    it 'raises MetaAttributeError if _additional symbol key is present' do
      expect do
        instance.send(:validate_record_for_update, { _additional: 'test' })
      end.to raise_error(WeaviateRecord::Errors::MetaAttributeError, 'cannot update meta attributes')
    end

    it 'raises ArgumentError if attributes_hash is empty' do
      expect { instance.send(:validate_record_for_update, {}) }.to raise_error(ArgumentError)
    end
  end

  describe '#validate_and_save' do
    it 'raises CustomQueriedRecordError if it is a queried record' do
      instance.instance_variable_set(:@custom_selected, true)
      expect do
        instance.send(:validate_and_save)
      end.to raise_error(WeaviateRecord::Errors::CustomQueriedRecordError, 'cannot modify custom selected record')
    end

    context 'when id is nil' do
      before { instance.instance_variable_set(:@meta_attributes, { 'id' => nil }) }

      it 'calls #create_or_update_record' do
        allow(instance).to receive(:create_or_update_record).and_return({})
        instance.send(:validate_and_save)
        expect(instance).to have_received(:create_or_update_record)
      end
    end

    context 'when id is not nil' do
      before { instance.instance_variable_set(:@meta_attributes, { 'id' => 123 }) }

      it 'calls #create_or_update_record' do
        allow(instance).to receive(:create_or_update_record).and_return({})
        instance.send(:validate_and_save)
        expect(instance).to have_received(:create_or_update_record)
      end
    end

    it 'raises InternalError if result is not a hash' do
      instance.instance_variable_set(:@meta_attributes, { 'id' => 123 })
      allow(instance).to receive(:create_or_update_record).and_return('')
      expect do
        instance.send(:validate_and_save)
      end.to raise_error(WeaviateRecord::Errors::InternalError, 'unable to save the record on Weaviate')
    end
  end

  describe '#validate_record_for_destroy' do
    it 'raises CustomQueriedRecordError if it is a queried record' do
      instance.instance_variable_set(:@custom_selected, true)
      expect do
        instance.send(:validate_record_for_destroy)
      end.to raise_error(WeaviateRecord::Errors::CustomQueriedRecordError,
                         'cannot perform destroy action on custom selected record')
    end

    context 'when id is nil' do
      before do
        instance.instance_variable_set(:@attributes, { 'title' => 'test', 'content' => 'this is test' })
        instance.instance_variable_set(:@meta_attributes, { 'id' => nil })
      end

      it 'returns false' do
        expect(instance.send(:validate_record_for_destroy)).to be false
      end

      it 'sets attributes to nil' do
        instance.send(:validate_record_for_destroy)
        instance.instance_variable_get(:@attributes).each_value do |value|
          expect(value).to be_nil
        end
      end
    end

    context 'when id is not nil' do
      it 'returns true' do
        instance.instance_variable_set(:@meta_attributes, { 'id' => 123 })
        expect(instance.send(:validate_record_for_destroy)).to be true
      end
    end
  end

  describe '#run_attribute_handlers' do
    it 'calls #check_attributes' do
      expect(instance).to receive(:check_attributes).with({ 'type' => 'test' })
      instance.send(:run_attribute_handlers, { 'type' => 'test' })
    end

    it 'calls #load_attributes' do
      expect(instance).to receive(:load_attributes).with({ 'type' => 'test' })
      instance.send(:run_attribute_handlers, { 'type' => 'test' })
    end

    it 'calls #create_attribute_writers' do
      expect(instance).to receive(:create_attribute_writers)
      instance.send(:run_attribute_handlers, { 'type' => 'test' })
    end

    it 'calls #create_attribute_readers' do
      expect(instance).to receive(:create_attribute_readers)
      instance.send(:run_attribute_handlers, { 'type' => 'test' })
    end
  end

  describe '#additional_attributes' do
    let(:record) do
      {
        'id' => 123,
        'creationTimeUnix' => 1_000_000,
        'lastUpdateTimeUnix' => 1_000_000
      }
    end

    it 'returns the formatted additional attributes' do
      expect(klass.send(:meta_attributes, record)).to eql({ 'id' => 123,
                                                            'created_at' => DateTime.strptime('1000000', '%Q'),
                                                            'updated_at' => DateTime.strptime('1000000', '%Q') })
    end
  end
end
