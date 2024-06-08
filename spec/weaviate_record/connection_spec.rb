# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Connection do
  let(:instance) { described_class.new('Article') }

  describe '#client' do
    it 'returns Weavaite::Client object' do
      expect(instance.client).to be_an_instance_of(Weaviate::Client)
    end

    it 'connects with weaviate database' do
      expect(instance.client.url).to eq(ENV.fetch('WEAVIATE_DATABASE_URL', nil))
    end
  end

  describe '#create_call' do
    it 'calls the create method on objects' do
      expect(instance.client.objects).to receive(:create).with(class_name: 'Article',
                                                               properties: { name: 'John' })
      instance.create_call({ name: 'John' })
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.create_call({ name: 'John' })
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#update_call' do
    it 'calls the update method on objects' do
      expect(instance.client.objects).to receive(:update).with(class_name: 'Article', id: '123',
                                                               properties: { name: 'John' })
      instance.update_call('123', { name: 'John' })
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.update_call('123', { name: 'John' })
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#delete_call' do
    it 'calls the delete method on objects' do
      expect(instance.client.objects).to receive(:delete).with(class_name: 'Article', id: '123')
      instance.delete_call('123')
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.delete_call('123')
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#find_call' do
    it 'calls the get method on objects' do
      expect(instance.client.objects).to receive(:get).with(class_name: 'Article', id: '123')
      instance.find_call('123')
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.find_call('123')
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#check_existence' do
    it 'calls the exists? method on objects' do
      expect(instance.client.objects).to receive(:exists?).with(class_name: 'Article', id: '123')
      instance.check_existence('123')
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.check_existence('123')
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#delete_where' do
    it 'calls the batch_delete method on objects' do
      expect(instance.client.objects).to receive(:batch_delete).with(class_name: 'Article', where: { name: 'John' })
      instance.delete_where({ name: 'John' })
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.delete_where({ name: 'John' })
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end

  describe '#schema_list' do
    it 'calls the list method on schema' do
      allow(instance.client.schema).to receive(:list).and_return({})
      instance.schema_list
      expect(instance.client.schema).to have_received(:list)
    end

    it 'raises an error if database is not connected' do
      allow(instance).to receive(:client).and_raise(Faraday::ConnectionFailed.new('Failed to connect'))
      expect do
        instance.schema_list
      end.to raise_error(WeaviateRecord::Errors::DatabaseNotConnected, 'Failed to connect')
    end
  end
end
