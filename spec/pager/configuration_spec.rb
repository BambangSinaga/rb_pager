# require "spec_helper"

RSpec.describe Pager::Configuration do
  describe '#limit' do
    it 'returns default value' do
      config = described_class.new

      expect(config.limit).to eql 20
    end
  end

  describe '#limit=' do
    context 'limit less or equal than max_limit' do
      it 'returns assigned value' do
        config = described_class.new
        config.limit = 10

        expect(config.limit).to eql 10
      end
    end

    context 'limit greater than max_limit' do
      it 'returns max_limit' do
        config = described_class.new
        config.limit = 110

        expect(config.limit).to eql 100
      end
    end
  end

  describe '#max_limit' do
    it 'returns default value' do
      config = described_class.new

      expect(config.max_limit).to eql 100
    end
  end

  describe '#max_limit=' do
    it 'returns assigned value' do
      config = described_class.new
      config.max_limit = 20

      expect(config.max_limit).to eql 20
    end
  end
end
