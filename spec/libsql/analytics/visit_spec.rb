# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Libsql::Analytics::Visit do
  let(:request) do
    double(
      url: 'https://example.com/products?utm_source=google&utm_medium=cpc',
      referer: 'https://google.com',
      remote_ip: '1.2.3.4',
      user_agent: 'Mozilla/5.0'
    )
  end

  describe '.track' do
    before do
      allow(described_class).to receive(:create!).and_return(double(id: '01ABCDEF'))
    end

    it 'calls create! with extracted url components' do
      expect(described_class).to receive(:create!).with(
        hash_including(
          host: 'example.com',
          path: '/products',
          query: 'utm_source=google&utm_medium=cpc',
          referrer: 'https://google.com',
          visitor_id: 'visitor-ulid'
        )
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(request: request, visitor_id: 'visitor-ulid')
    end

    it 'parses query_params as JSON' do
      expect(described_class).to receive(:create!).with(
        hash_including(
          query_params: include('utm_source')
        )
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(request: request, visitor_id: 'visitor-ulid')
    end

    it 'stores metadata as JSON when provided' do
      expect(described_class).to receive(:create!).with(
        hash_including(
          metadata: include('1.2.3.4')
        )
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(
        request: request,
        visitor_id: 'visitor-ulid',
        metadata: { ip: '1.2.3.4', user_agent: 'Mozilla/5.0' }
      )
    end

    it 'stores nil for metadata when empty' do
      expect(described_class).to receive(:create!).with(
        hash_including(metadata: nil)
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(request: request, visitor_id: 'visitor-ulid')
    end

    it 'stores nil for account_identity when not provided' do
      expect(described_class).to receive(:create!).with(
        hash_including(account_identity: nil)
      ).and_return(double(id: '01ABCDEF'))

      described_class.track(request: request, visitor_id: 'visitor-ulid')
    end

    context 'when URL has no query string' do
      let(:request) do
        double(
          url: 'https://example.com/about',
          referer: nil,
          remote_ip: '1.2.3.4',
          user_agent: 'Mozilla/5.0'
        )
      end

      it 'stores nil for query and query_params' do
        expect(described_class).to receive(:create!).with(
          hash_including(query: nil, query_params: nil)
        ).and_return(double(id: '01ABCDEF'))

        described_class.track(request: request, visitor_id: 'visitor-ulid')
      end
    end
  end
end
