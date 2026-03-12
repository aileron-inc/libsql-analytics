# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Event do
  describe '.track' do
    before do
      allow(described_class).to receive(:create!).and_return(double(id: '01ABCDEF'))
    end

    it 'calls create! with name and event_at' do
      expect(described_class).to receive(:create!).with(
        hash_including(
          name: 'Clicked Signup',
          visit_id: 'visit-ulid'
        )
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(name: 'Clicked Signup', visit_id: 'visit-ulid')
    end

    it 'stores properties as JSON when provided' do
      expect(described_class).to receive(:create!).with(
        hash_including(properties: include('pro'))
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(name: 'Signup', properties: { plan: 'pro' })
    end

    it 'stores nil for properties when empty' do
      expect(described_class).to receive(:create!).with(
        hash_including(properties: nil)
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(name: 'Page Viewed')
    end

    it 'stores nil for visit_id when not provided' do
      expect(described_class).to receive(:create!).with(
        hash_including(visit_id: nil)
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(name: 'Anonymous Event')
    end
  end
end
