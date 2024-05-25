# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::Order do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::Order
      attr_writer :loaded
    end
  end
  let(:instance) { klass.new }

  describe '#order' do
    it 'sets loaded to false' do
      instance.loaded = true
      instance.order(:title)
      expect(instance.instance_variable_get(:@loaded)).to be_falsey
    end

    it 'returns self' do
      expect(instance.order(:title)).to be(instance)
    end

    it 'raises an error if no arguments are passed' do
      expect do
        instance.order
      end.to raise_error(ArgumentError, 'expected at least one argument')
    end

    # context 'On queries' do
    #   context 'for single argument' do
    #     let!(:documents) do
    #       10.times.map do |index|
    #         DocumentTest.create(title: "test document #{index}")
    #       end
    #     end
    #     after { documents.each(&:destroy) }

    #     it 'sorts the records' do
    #       expect(DocumentTest.order(:title).map(&:title)).to eq(documents.map(&:title).sort)
    #     end

    #     it 'can take keyword arguments for sorting order' do
    #       expect(DocumentTest.order(title: :desc).map(&:title)).to eq(documents.map(&:title).sort.reverse)
    #     end
    #   end

    #   context 'for multiple arguments' do
    #     let!(:documents) do
    #       6.times.map do |index|
    #         DocumentTest.create(title: "test document #{index & 1}")
    #       end
    #     end
    #     after { documents.each(&:destroy) }

    #     it 'sorts the records based on them' do
    #       expect(DocumentTest.order(:title, :id).map(&:id)).to eq(documents.sort_by { [_1.title, _1.id] }.map!(&:id))
    #     end
    #   end
    # end
  end

  describe '#combine_arguments' do
    before do
      allow(instance).to receive(:convert_to_sorting_specifier).and_call_original
    end

    context 'when it is for normal arguments' do
      it 'calls the convert_to_sorting_specifier with each argument' do
        instance.send(:combine_arguments, %i[title content type], {})
        %i[title content type].each do |argument|
          expect(instance).to have_received(:convert_to_sorting_specifier).with(argument)
        end
      end
    end

    context 'when keyword arguments are present' do
      it 'calls the combine_arguments with each key-value pair' do
        instance.send(:combine_arguments, [], { title: :desc, content: :asc })
        { title: :desc, content: :asc }.each do |pair|
          expect(instance).to have_received(:convert_to_sorting_specifier).with(*pair)
        end
      end
    end

    it 'returns an array of formatted sorting options' do
      expect(instance.send(:combine_arguments, [:title],
                           { content: :desc })).to eq(['{ path: ["title"], order: asc }',
                                                       '{ path: ["content"], order: desc }'])
    end
  end

  describe '#convert_to_sorting_specifier' do
    it 'raises an error if the attribute is not a symbol or string' do
      expect do
        instance.send(:convert_to_sorting_specifier, 1)
      end.to raise_error(TypeError, 'Invalid type for sorting attribute, should be either type or symbol')
    end

    it 'raises an error if the sorting order is invalid' do
      expect do
        instance.send(:convert_to_sorting_specifier, :title, :invalid)
      end.to raise_error(WeaviateRecord::Errors::SortingOptionError, 'Invalid sorting order')
    end

    it 'returns a formatted sorting specifier' do
      expect(instance.send(:convert_to_sorting_specifier, :title)).to eq('{ path: ["title"], order: asc }')
    end

    context 'when sorting order is specified' do
      it 'returns a formatted sorting specifier with mentioned order' do
        expect(instance.send(:convert_to_sorting_specifier, :title, :desc)).to eq('{ path: ["title"], order: desc }')
      end
    end

    context 'when additional attributes are present' do
      it 'prefixes underscore for id' do
        expect(instance.send(:convert_to_sorting_specifier, :id)).to eq('{ path: ["_id"], order: asc }')
      end

      it 'converts special attributes to their mapped name' do
        expect(instance.send(:convert_to_sorting_specifier,
                             :created_at)).to eq('{ path: ["_creationTimeUnix"], order: asc }')
      end
    end
  end

  describe '#assign_sort_options' do
    before do
      allow(instance).to receive(:merge_sorting_specifiers).and_call_original
    end

    context 'when sort_options is present' do
      context 'when sort_options starts with [' do
        it 'combines the attributes and assigns them to sort_options' do
          instance.instance_variable_set(:@sort_options, '[ 1, 2 ]')
          instance.send(:assign_sort_options, %w[3 4 5])
          expect(instance.instance_variable_get(:@sort_options)).to eq('[ 1, 2, 3, 4, 5 ]')
        end

        it 'calls merge_sorting_specifiers with the stripped sort_option' do
          instance.instance_variable_set(:@sort_options, '[ 1, 2 ]')
          instance.send(:assign_sort_options, %w[3 4 5])
          expect(instance).to have_received(:merge_sorting_specifiers).with('1, 2', '3', '4', '5')
        end
      end

      context 'when sort_options does not start with [' do
        it 'combines the attributes and assigns them to sort_options' do
          instance.instance_variable_set(:@sort_options, '1')
          instance.send(:assign_sort_options, %w[2 3 4])
          expect(instance.instance_variable_get(:@sort_options)).to eq('[ 1, 2, 3, 4 ]')
        end

        it 'calls combine_sorting_options with sort_option as it is' do
          instance.instance_variable_set(:@sort_options, '1')
          instance.send(:assign_sort_options, %w[2 3 4])
          expect(instance).to have_received(:merge_sorting_specifiers).with('1', '2', '3', '4')
        end
      end
    end

    context 'when sort_options is not present' do
      it 'combines the attributes in an array and assigns them to sort_options' do
        instance.send(:assign_sort_options, %w[1 2 3])
        expect(instance.instance_variable_get(:@sort_options)).to eq('[ 1, 2, 3 ]')
      end
    end
  end

  describe '#merge_sorting_specifiers' do
    it 'returns the first argument if there is only one' do
      expect(instance.send(:merge_sorting_specifiers, '1')).to eq('1')
    end

    it 'returns the combined arguments in an array' do
      expect(instance.send(:merge_sorting_specifiers, '1', '2', '3')).to eq('[ 1, 2, 3 ]')
    end
  end
end
