# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::NearObject do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::NearObject
    end
  end
  let(:instance) { klass.new }
  let(:article) { instance_double(Article, id: '123') }

  before do
    allow_any_instance_of(Article).to receive(:id)
    allow(article).to receive(:is_a?).with(WeaviateRecord::Base).and_return(true)
    allow(article).to receive(:is_a?).with(String).and_return(false)
  end

  describe '#near_object' do
    it 'raises TypeError if object is not a WeaviateRecord::Base or a String' do
      expect do
        instance.near_object(1)
      end.to raise_error(TypeError, 'Invalid type Integer for near object query')
    end

    it 'raises TypeError if object is a String and does not match UUID_REGEX' do
      expect do
        instance.near_object('123')
      end.to raise_error(TypeError, 'Invalid uuid')
    end

    it 'raises TypeError if distance is not numeric' do
      expect do
        instance.near_object(article, distance: 'a')
      end.to raise_error(TypeError, 'Invalid value for distance')
    end

    context 'when arguments are valid' do
      it 'sets @near_object to object.id if object is an weaviate record' do
        instance.near_object(article)
        expect(instance.instance_variable_get(:@near_object)).to eql('{ id: "123", distance: 0.55 }')
      end

      it 'sets @near_object to object if object is a string' do
        instance.near_object('a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6')
        expect(instance.instance_variable_get(:@near_object)).to eql('{ id: "a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6", ' \
                                                                     'distance: 0.55 }')
      end

      it 'sets @loaded to false' do
        instance.near_object(article)
        expect(instance.instance_variable_get(:@loaded)).to be false
      end

      it 'returns self' do
        expect(instance.near_object(article)).to be(instance)
      end
    end
  end
end
