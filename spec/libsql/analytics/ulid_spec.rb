# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Ulid do
  describe '.generate' do
    it 'returns a 26-character string' do
      expect(described_class.generate.length).to eq(26)
    end

    it 'returns only Crockford base32 characters' do
      ulid = described_class.generate
      expect(ulid).to match(/\A[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}\z/)
    end

    it 'generates unique values' do
      ulids = Array.new(100) { described_class.generate }
      expect(ulids.uniq.length).to eq(100)
    end

    it 'generates lexicographically sortable values (time-ordered)' do
      ulid1 = described_class.generate
      sleep(0.01)
      ulid2 = described_class.generate
      expect(ulid1 < ulid2).to be true
    end
  end
end
