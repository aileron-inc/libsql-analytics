# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Event do
  let(:db) { instance_double('Libsql::Analytics::Database') }
  let(:event) { described_class.new(db) }

  describe '#track' do
    before { allow(db).to receive(:execute) }

    it 'inserts a row into libsql_analytics_events' do
      expect(db).to receive(:execute) do |sql, params|
        expect(sql).to include('INSERT INTO libsql_analytics_events')
        expect(params[0]).to match(/\A[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}\z/) # id (ULID)
        expect(params[1]).to eq('visit-ulid-123')   # visit_id
        expect(params[2]).to eq('Clicked Signup')   # name
        expect(params[3]).to include('plan') # properties (JSON)
        expect(params[4]).to match(/\d{4}-\d{2}-\d{2}T/) # event_at
      end

      event.track(
        name: 'Clicked Signup',
        visit_id: 'visit-ulid-123',
        properties: { plan: 'pro' }
      )
    end

    it 'returns a ULID' do
      result = event.track(name: 'Page Viewed')
      expect(result).to match(/\A[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}\z/)
    end

    context 'when properties is empty' do
      it 'stores nil for properties' do
        expect(db).to receive(:execute) do |_sql, params|
          expect(params[3]).to be_nil
        end

        event.track(name: 'Page Viewed')
      end
    end

    context 'when visit_id is not provided' do
      it 'stores nil for visit_id' do
        expect(db).to receive(:execute) do |_sql, params|
          expect(params[1]).to be_nil
        end

        event.track(name: 'Anonymous Event')
      end
    end
  end
end
