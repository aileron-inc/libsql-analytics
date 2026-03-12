# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics do
  after do
    described_class.instance_variable_set(:@configuration, nil)
  end

  describe '.configure' do
    before do
      # establish_connection! は実 DB 不要なのでスタブ
      allow(Libsql::Analytics::Record).to receive(:establish_connection)
    end

    it 'yields the configuration object' do
      described_class.configure do |config|
        config.url           = 'libsql://example.turso.io'
        config.token         = 'my-token'
        config.sync_interval = 30
      end

      expect(described_class.configuration.url).to eq('libsql://example.turso.io')
      expect(described_class.configuration.token).to eq('my-token')
      expect(described_class.configuration.sync_interval).to eq(30)
    end

    it 'calls establish_connection on Record with correct config' do
      expect(Libsql::Analytics::Record).to receive(:establish_connection).with(
        hash_including(
          adapter: 'turso',
          database: 'libsql://example.turso.io',
          token: 'my-token'
        )
      )

      described_class.configure do |config|
        config.url   = 'libsql://example.turso.io'
        config.token = 'my-token'
      end
    end
  end

  describe '.configured?' do
    context 'when url is not set' do
      it { expect(described_class.configured?).to be false }
    end

    context 'when url is set' do
      before do
        allow(Libsql::Analytics::Record).to receive(:establish_connection)
        described_class.configure { |c| c.url = 'libsql://example.turso.io' }
      end

      it { expect(described_class.configured?).to be true }
    end
  end
end
