# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::NearVector do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::NearVector
    end
  end
  let(:instance) { klass.new }

  describe '#near_vector' do
    it 'raises TypeError if vector is not an array' do
      expect do
        instance.near_vector(1)
      end.to raise_error(TypeError, 'Invalid type Integer for near vector query')
    end

    it 'raises TypeError if vector is not a valid vector' do
      expect do
        instance.near_vector([1, 2, 3])
      end.to raise_error(TypeError, 'Invalid vector')
    end

    it 'raises TypeError if distance is not a float' do
      expect do
        instance.near_vector([1.0, 2.0, -3.0], distance: 'a')
      end.to raise_error(TypeError, 'Invalid value for distance')
    end

    context 'when arguments are valid' do
      it 'sets @near_vector to vector' do
        instance.near_vector([1.0, 2.0, -3.0])
        expect(instance.instance_variable_get(:@near_vector)).to eql('{ vector: [1.0, 2.0, -3.0], distance: 0.55 }')
      end

      it 'sets @loaded to false' do
        instance.near_vector([1.0, 2.0, -3.0])
        expect(instance.instance_variable_get(:@loaded)).to be false
      end

      it 'returns self' do
        expect(instance.near_vector([1.0, 2.0, -3.0])).to be(instance)
      end

      context 'when distance is given' do
        it 'sets @near_vector to vector and distance' do
          instance.near_vector([1.0, 2.0, -3.0], distance: 0.6)
          expect(instance.instance_variable_get(:@near_vector)).to eql('{ vector: [1.0, 2.0, -3.0], distance: 0.6 }')
        end
      end
    end
  end
end
