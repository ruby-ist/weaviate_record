# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeaviateRecord::Queries::NearText do
  let(:klass) do
    Class.new do
      include WeaviateRecord::Queries::NearText
    end
  end
  let(:instance) { klass.new }

  before do
    instance.instance_variable_set(:@near_text_options, {
                                     concepts: [],
                                     distance: WeaviateRecord.config.near_text_default_distance
                                   })
  end

  describe '#near_text' do
    context 'when the text is invalid type' do
      it 'raises a TypeError' do
        expect { instance.near_text(1) }.to raise_error(TypeError, 'invalid value for text')
      end
    end

    context 'when the distance is invalid type' do
      it 'raises a TypeError' do
        expect { instance.near_text('text', distance: '1') }.to raise_error(TypeError, 'Invalid value for distance')
      end
    end

    context 'when input is valid' do
      it 'adds the text to the near_text_options' do
        instance.near_text('text')
        expect(instance.instance_variable_get(:@near_text_options)[:concepts]).to eq(['text'])
      end

      context 'when the distance is not given' do
        it 'sets the distance to default distance' do
          instance.near_text('text')
          expect(instance
                   .instance_variable_get(:@near_text_options)[:distance])
            .to eq(WeaviateRecord.config.near_text_default_distance)
        end
      end

      context 'when the distance is given' do
        it 'sets the distance to the given value' do
          instance.near_text('text', distance: 0.5)
          expect(instance.instance_variable_get(:@near_text_options)[:distance]).to eq(0.5)
        end
      end
    end

    context 'when the text contains double quotes' do
      it 'replaces the double quotes with single quotes' do
        instance.near_text('this is "test"')
        expect(instance.instance_variable_get(:@near_text_options)[:concepts]).to eq(["this is 'test'"])
      end
    end

    it 'sets loaded to false' do
      instance.near_text('text')
      expect(instance.instance_variable_get(:@loaded)).to be(false)
    end

    it 'returns self' do
      expect(instance.near_text('text')).to eq(instance)
    end

    context 'with queries' do
      let!(:articles) do
        [Article.create(content: 'Rently was established in 2011'),
         Article.create(content: 'Sometimes rently may ban a lead for suspicious reason'),
         Article.create(content: 'Rently is a company that provides self-showing technology')]
      end

      after { articles.each(&:destroy) }

      it 'returns the record based on semantic search' do
        expect(Article.near_text('why my lead got banned').first.id).to eq(articles[1].id)
      end
    end
  end

  describe '#formatted_near_text_value' do
    it 'returns the formatted near_text options' do
      instance.instance_variable_set(:@near_text_options, { concepts: %w[text1 text2], distance: 0.5 })
      expect(instance.send(:formatted_near_text_value)).to eq('{ concepts: ["text1", "text2"], distance: 0.5 }')
    end
  end
end
