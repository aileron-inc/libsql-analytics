# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Visit do
  let(:db) { instance_double('Libsql::Analytics::Database') }
  let(:visit) { described_class.new(db) }

  describe '#id' do
    it 'is a ULID' do
      expect(visit.id).to match(/\A[0123456789ABCDEFGHJKMNPQRSTVWXYZ]{26}\z/)
    end
  end

  describe '#track' do
    let(:request) do
      instance_double(
        'ActionDispatch::Request',
        url: 'https://example.com/products?utm_source=google&utm_medium=cpc',
        referer: 'https://google.com',
        remote_ip: '1.2.3.4',
        user_agent: 'Mozilla/5.0'
      )
    end

    before do
      allow(db).to receive(:execute)
    end

    it 'inserts a row into libsql_analytics_visits' do
      expect(db).to receive(:execute) do |sql, params|
        expect(sql).to include('INSERT INTO libsql_analytics_visits')
        expect(params[0]).to eq(visit.id) # id
        expect(params[1]).to eq('visitor-ulid-123')  # visitor_id
        expect(params[2]).to eq('account-abc')       # account_identity
        expect(params[3]).to eq('https://google.com') # referrer
        expect(params[4]).to eq('example.com')        # host
        expect(params[5]).to include('utm_source=google') # url
        expect(params[6]).to eq('/products') # path
        expect(params[7]).to eq('utm_source=google&utm_medium=cpc') # query (raw)
        expect(params[8]).to include('utm_source')     # query_params (JSON)
        expect(params[9]).to be_nil                    # metadata (empty hash → nil)
        expect(params[10]).to match(/\d{4}-\d{2}-\d{2}T/) # started_at
      end

      visit.track(
        request: request,
        visitor_id: 'visitor-ulid-123',
        account_identity: 'account-abc'
      )
    end

    it 'returns the visit id' do
      result = visit.track(request: request, visitor_id: 'visitor-ulid-123')
      expect(result).to eq(visit.id)
    end

    context 'when metadata is provided' do
      it 'stores metadata as JSON' do
        expect(db).to receive(:execute) do |_sql, params|
          metadata = JSON.parse(params[9])
          expect(metadata['ip']).to eq('1.2.3.4')
          expect(metadata['user_agent']).to include('Mozilla')
        end

        visit.track(
          request: request,
          visitor_id: 'visitor-ulid-123',
          metadata: { ip: '1.2.3.4', user_agent: 'Mozilla/5.0' }
        )
      end
    end

    context 'when URL has no query string' do
      let(:request) do
        instance_double(
          'ActionDispatch::Request',
          url: 'https://example.com/about',
          referer: nil,
          remote_ip: '1.2.3.4',
          user_agent: 'Mozilla/5.0'
        )
      end

      it 'stores nil for query and query_params' do
        expect(db).to receive(:execute) do |_sql, params|
          expect(params[7]).to be_nil # query
          expect(params[8]).to be_nil # query_params
        end

        visit.track(request: request, visitor_id: 'visitor-ulid-123')
      end
    end
  end
end
