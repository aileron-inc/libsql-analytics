# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics do
  after do
    # 各テスト後に設定をリセット
    described_class.instance_variable_set(:@configuration, nil)
    described_class.instance_variable_set(:@db, nil)
  end

  describe '.configure' do
    it 'yields the configuration object' do
      described_class.configure do |config|
        config.url = 'libsql://example.turso.io'
        config.token = 'my-token'
        config.sync_interval = 30
      end

      expect(described_class.configuration.url).to eq('libsql://example.turso.io')
      expect(described_class.configuration.token).to eq('my-token')
      expect(described_class.configuration.sync_interval).to eq(30)
    end

    it 'resets the db connection on reconfigure' do
      described_class.instance_variable_set(:@db, double('db'))
      described_class.configure { |c| c.url = 'libsql://example.turso.io' }
      expect(described_class.instance_variable_get(:@db)).to be_nil
    end
  end

  describe '.configured?' do
    context 'when url is not set' do
      it { expect(described_class.configured?).to be false }
    end

    context 'when url is set' do
      before { described_class.configure { |c| c.url = 'libsql://example.turso.io' } }
      it { expect(described_class.configured?).to be true }
    end
  end
end
