# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it { expect(config.url).to be_nil }
    it { expect(config.token).to be_nil }
    it { expect(config.replica_path).to eq('storage/analytics.db') }
    it { expect(config.sync_interval).to eq(60) }
    it { expect(config.account_identity).to be_nil }
    it { expect(config.skip_paths).to eq(['/assets', '/favicon']) }
  end

  describe '#validate!' do
    context 'when url is nil' do
      it 'raises ArgumentError' do
        expect { config.validate! }.to raise_error(ArgumentError, /url is required/)
      end
    end

    context 'when url is set' do
      before { config.url = 'libsql://example.turso.io' }

      it 'does not raise' do
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'when replica_path is nil' do
      before do
        config.url = 'libsql://example.turso.io'
        config.replica_path = nil
      end

      it 'raises ArgumentError' do
        expect { config.validate! }.to raise_error(ArgumentError, /replica_path is required/)
      end
    end
  end
end
