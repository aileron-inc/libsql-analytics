# frozen_string_literal: true

require 'spec_helper'

# 実 Turso DB へのアクセスが必要な integration spec
# LIBSQL_ANALYTICS_URL / LIBSQL_ANALYTICS_TOKEN が未設定の場合はスキップする
RSpec.describe 'Integration: Libsql::Analytics', :integration do
  let(:url)          { ENV['LIBSQL_ANALYTICS_URL'] }
  let(:token)        { ENV['LIBSQL_ANALYTICS_TOKEN'] }
  let(:replica_path) { "tmp/test_analytics_#{Process.pid}.db" }

  before(:all) do
    skip 'LIBSQL_ANALYTICS_URL not set' unless ENV['LIBSQL_ANALYTICS_URL']
  end

  before do
    cleanup_replica!

    Libsql::Analytics.configure do |c|
      c.url           = url
      c.token         = token
      c.replica_path  = replica_path
      c.sync_interval = 0
    end

    Libsql::Analytics::Migrator.new.migrate!
  end

  after do
    # テストデータを削除してからファイルを消す
    begin
      Libsql::Analytics::Event.delete_all
    rescue StandardError
      nil
    end
    begin
      Libsql::Analytics::Visit.delete_all
    rescue StandardError
      nil
    end
    cleanup_replica!
    Libsql::Analytics.instance_variable_set(:@configuration, nil)
  end

  def cleanup_replica!
    Dir.glob("#{replica_path}*").each { |f| FileUtils.rm_f(f) }
  end

  let(:request) do
    double(
      url: 'https://example.com/products?utm_source=google',
      referer: 'https://google.com',
      remote_ip: '1.2.3.4',
      user_agent: 'Mozilla/5.0'
    )
  end

  describe 'Visit tracking' do
    it 'inserts a visit and reads it back via AR' do
      visit = Libsql::Analytics::Visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate,
        account_identity: 'user-abc',
        metadata: { ip: '1.2.3.4', user_agent: 'Mozilla/5.0' }
      )

      found = Libsql::Analytics::Visit.find(visit.id)
      expect(found.account_identity).to eq('user-abc')
      expect(found.host).to eq('example.com')
      expect(found.path).to eq('/products')
      expect(found.query).to eq('utm_source=google')
      expect(found.query_params).to include('utm_source')
      expect(found.referrer).to eq('https://google.com')
      expect(found.metadata).to include('1.2.3.4')
    end

    it 'stores nil for account_identity when not logged in' do
      visit = Libsql::Analytics::Visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate
      )

      found = Libsql::Analytics::Visit.find(visit.id)
      expect(found.account_identity).to be_nil
    end
  end

  describe 'Event tracking' do
    it 'inserts an event and reads it back via AR' do
      visit = Libsql::Analytics::Visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate
      )

      event = Libsql::Analytics::Event.track(
        name: 'Clicked Signup',
        visit_id: visit.id,
        properties: { plan: 'pro' }
      )

      found = Libsql::Analytics::Event.find(event.id)
      expect(found.visit_id).to eq(visit.id)
      expect(found.name).to eq('Clicked Signup')
      expect(found.properties).to include('pro')
      expect(found.event_at).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'tracks an event without a visit' do
      event = Libsql::Analytics::Event.track(name: 'Background Job Completed')

      found = Libsql::Analytics::Event.find(event.id)
      expect(found.visit_id).to be_nil
    end
  end

  describe 'Migrator' do
    it 'creates tables idempotently' do
      migrator = Libsql::Analytics::Migrator.new
      expect { migrator.migrate! }.not_to raise_error
      expect { migrator.migrate! }.not_to raise_error
    end

    it 'creates libsql_analytics_visits table' do
      expect(Libsql::Analytics::Record.connection.table_exists?('libsql_analytics_visits')).to be true
    end

    it 'creates libsql_analytics_events table' do
      expect(Libsql::Analytics::Record.connection.table_exists?('libsql_analytics_events')).to be true
    end
  end
end
