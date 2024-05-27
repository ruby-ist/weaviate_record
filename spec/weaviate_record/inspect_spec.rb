# frozen_string_literal: true

# frozen string literal: true

require 'spec_helper'

describe WeaviateRecord::Inspect do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Inspect
    end
  end
  let(:instance) { klass.new }

  before do
    instance.instance_variable_set('@attributes', { 'id' => 1,
                                                    'content' => 'A very long text that is needed to test ' \
                                                                 'the truncate method on inspect',
                                                    'categories' => ['test'] })
    instance.instance_variable_set('@meta_attributes', { 'distance' => 0.345, 'vector' => [1, 2, 3, 4, 5],
                                                         'created_at' => DateTime.new(2024, 2, 11, 12, 0, 0),
                                                         'updated_at' => DateTime.new(2024, 2, 11, 12, 1, 0) })
  end

  describe '#inspect' do
    it 'returns a string' do
      expect(instance.inspect).to be_a(String)
    end

    it 'prints record id after class' do
      expect(instance.inspect.match(/(?<=\s)(\w+):/)[1]).to eq('id')
    end

    it 'prints created_at at second to last last' do
      expect(instance.inspect.scan(/([\w_]+):\s/)[-2]).to eq(['created_at'])
    end

    it 'prints updated_at at last' do
      expect(instance.inspect.scan(/([\w_]+):\s/)[-1]).to eq(['updated_at'])
    end

    it 'does not print created_at and updated_at if they are not listed' do
      instance.instance_variable_set('@meta_attributes', { 'distance' => 0.345, 'vector' => [1, 2, 3, 4, 5] })
      expect(instance.inspect).not_to include('created_at', 'updated_at')
    end
  end

  describe '#format_attributes' do
    it 'returns attributes in sorted manner' do
      attributes = %w[categories content distance vector]
      _, inspection = instance.send(:format_attributes)
      inspection_attributes = inspection.scan(/([\w_]+):/).map! { _1[0] }
      expect(inspection_attributes).to eq(attributes)
    end

    it 'slices special attributes' do
      special_attributes, = instance.send(:format_attributes)
      expect(special_attributes.keys).to include('id', 'created_at', 'updated_at')
    end
  end

  describe '#format_for_inspect' do
    context 'when the value is a string' do
      it 'returns the string truncated to 25 characters' do
        key = 'content'
        value = 'This is a very long string that should be truncated'
        expect(instance.send(:format_for_inspect, key, value)).to eq("content: #{value.truncate(25).inspect}")
      end
    end

    context 'when the value is an array' do
      context 'when the key equals vector' do
        it 'returns the truncated array' do
          key = 'vector'
          value = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
          expect(instance.send(:format_for_inspect, key, value)).to eq('vector: [1, 2, 3, 4...]')
        end
      end

      context 'when the key not equals vector' do
        it 'returns the array as string' do
          key = 'categories'
          value = ['single family', 'multi family', 'renter support', 'keyless support', 'resident app']
          expect(instance.send(:format_for_inspect, key, value)).to eq("categories: #{value.inspect}")
        end
      end
    end

    context 'when the value is not a string or an array' do
      it 'returns the value as a string' do
        key = 'distance'
        value = 0.25
        expect(instance.send(:format_for_inspect, key, value)).to eq('distance: 0.25')
      end
    end

    context 'when the key is in camel case' do
      it 'returns the key in snake case' do
        key = 'featureProjection'
        value = nil
        expect(instance.send(:format_for_inspect, key, value)).to eq('feature_projection: nil')
      end
    end
  end
end
