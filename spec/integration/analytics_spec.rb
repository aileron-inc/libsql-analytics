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

  def cleanup_replica!
    # replica_path に関連する全ファイルを削除（metadata / shm / wal 含む）
    Dir.glob("#{replica_path}*").each { |f| FileUtils.rm_f(f) }
    # 設定・接続をリセット
    Libsql::Analytics.instance_variable_set(:@configuration, nil)
    Libsql::Analytics.instance_variable_set(:@db, nil)
  end

  before do
    cleanup_replica! # 前回テストの残骸を確実に除去

    Libsql::Analytics.configure do |c|
      c.url           = url
      c.token         = token
      c.replica_path  = replica_path
      c.sync_interval = 0 # テストでは手動 sync のみ
    end

    Libsql::Analytics::Migrator.new(Libsql::Analytics.db).migrate!
  end

  after do
    cleanup_replica!
  end

  describe 'Visit tracking' do
    it 'inserts a visit and reads it back' do
      db = Libsql::Analytics.db
      visit = Libsql::Analytics::Visit.new(db)

      request = double(
        url: 'https://example.com/products?utm_source=google',
        referer: 'https://google.com',
        remote_ip: '1.2.3.4',
        user_agent: 'Mozilla/5.0'
      )

      visit_id = visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate,
        account_identity: 'user-abc',
        metadata: { ip: '1.2.3.4', user_agent: 'Mozilla/5.0' }
      )

      rows = db.query("SELECT * FROM libsql_analytics_visits WHERE id = '#{visit_id}'")

      expect(rows.length).to eq(1)
      row = rows.first
      expect(row['id']).to eq(visit_id)
      expect(row['account_identity']).to eq('user-abc')
      expect(row['host']).to eq('example.com')
      expect(row['path']).to eq('/products')
      expect(row['query']).to eq('utm_source=google')
      expect(row['query_params']).to include('utm_source')
      expect(row['referrer']).to eq('https://google.com')
      expect(row['metadata']).to include('1.2.3.4')
    end

    it 'stores NULL for account_identity when not logged in' do
      db = Libsql::Analytics.db
      visit = Libsql::Analytics::Visit.new(db)

      request = double(
        url: 'https://example.com/',
        referer: nil,
        remote_ip: '9.9.9.9',
        user_agent: 'curl/7.0'
      )

      visit_id = visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate
      )

      rows = db.query("SELECT * FROM libsql_analytics_visits WHERE id = '#{visit_id}'")
      expect(rows.first['account_identity']).to be_nil
    end
  end

  describe 'Event tracking' do
    it 'inserts an event and reads it back' do
      db = Libsql::Analytics.db
      visit = Libsql::Analytics::Visit.new(db)
      event = Libsql::Analytics::Event.new(db)

      request = double(
        url: 'https://example.com/signup',
        referer: nil,
        remote_ip: '1.2.3.4',
        user_agent: 'Mozilla/5.0'
      )

      visit_id = visit.track(
        request: request,
        visitor_id: Libsql::Analytics::Ulid.generate
      )

      event_id = event.track(
        name: 'Clicked Signup',
        visit_id: visit_id,
        properties: { plan: 'pro', source: 'banner' }
      )

      rows = db.query("SELECT * FROM libsql_analytics_events WHERE id = '#{event_id}'")

      expect(rows.length).to eq(1)
      row = rows.first
      expect(row['id']).to eq(event_id)
      expect(row['visit_id']).to eq(visit_id)
      expect(row['name']).to eq('Clicked Signup')
      expect(row['properties']).to include('pro')
      expect(row['event_at']).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'tracks an event without a visit' do
      db = Libsql::Analytics.db
      event = Libsql::Analytics::Event.new(db)

      event_id = event.track(name: 'Background Job Completed')

      rows = db.query("SELECT * FROM libsql_analytics_events WHERE id = '#{event_id}'")
      expect(rows.first['visit_id']).to be_nil
    end
  end

  describe 'Migrator' do
    it 'creates tables idempotently' do
      migrator = Libsql::Analytics::Migrator.new(Libsql::Analytics.db)
      expect { migrator.migrate! }.not_to raise_error
      expect { migrator.migrate! }.not_to raise_error
    end

    it 'creates libsql_analytics_visits table' do
      db = Libsql::Analytics.db
      rows = db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='libsql_analytics_visits'")
      expect(rows).not_to be_empty
    end

    it 'creates libsql_analytics_events table' do
      db = Libsql::Analytics.db
      rows = db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='libsql_analytics_events'")
      expect(rows).not_to be_empty
    end
  end
end
