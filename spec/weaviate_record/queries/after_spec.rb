# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::After do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::After
    end
  end
  let(:instance) { klass.new }

  before do
    instance.instance_variable_set(:@klass, RSpec::Mocks::InstanceVerifyingDouble)
  end

  describe '#after' do
    it 'raises TypeError if object is not an instance of klass or a string' do
      expect do
        instance.after(1)
      end.to raise_error(TypeError, 'Invalid type Integer for object query')
    end

    it 'raises ArgumentError if object is a string and not a valid uuid' do
      expect do
        instance.after('123')
      end.to raise_error(TypeError, 'Invalid uuid')
    end

    context 'when object is valid' do
      it 'sets @after to object id if object is an instance of klass' do
        allow_any_instance_of(Article).to receive(:id)
        instance.after(instance_double(Article, id: '123'))
        expect(instance.instance_variable_get(:@after)).to eql('123')
      end

      it 'sets @after to object if object is a valid uuid' do
        instance.after('a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6')
        expect(instance.instance_variable_get(:@after)).to eql('a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6')
      end

      it 'sets @loaded to false' do
        instance.after('a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6')
        expect(instance.instance_variable_get(:@loaded)).to be false
      end

      it 'returns self' do
        expect(instance.after('a1b2c3d4-a1b2-c3d4-e5f6-a1b2c3d4e5f6')).to be(instance)
      end
    end
  end
end
