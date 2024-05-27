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
  end

  describe '#update_call' do
    it 'calls the update method on objects' do
      expect(instance.client.objects).to receive(:update).with(class_name: 'Article', id: '123',
                                                               properties: { name: 'John' })
      instance.update_call('123', { name: 'John' })
    end
  end

  describe '#delete_call' do
    it 'calls the delete method on objects' do
      expect(instance.client.objects).to receive(:delete).with(class_name: 'Article', id: '123')
      instance.delete_call('123')
    end
  end

  describe '#find_call' do
    it 'calls the get method on objects' do
      expect(instance.client.objects).to receive(:get).with(class_name: 'Article', id: '123')
      instance.find_call('123')
    end
  end
end
