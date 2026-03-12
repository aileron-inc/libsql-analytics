# frozen_string_literal: true

module Libsql
  module Analytics
    class Migrator
      VISITS_DDL = <<~SQL
        CREATE TABLE IF NOT EXISTS libsql_analytics_visits (
          id               TEXT PRIMARY KEY,
          visitor_id       TEXT,
          account_identity TEXT,
          referrer         TEXT,
          host             TEXT,
          url              TEXT,
          path             TEXT,
          query            TEXT,
          query_params     TEXT,
          metadata         TEXT,
          started_at       TEXT NOT NULL
        )
      SQL

      EVENTS_DDL = <<~SQL
        CREATE TABLE IF NOT EXISTS libsql_analytics_events (
          id         TEXT PRIMARY KEY,
          visit_id   TEXT,
          name       TEXT NOT NULL,
          properties TEXT,
          event_at   TEXT NOT NULL
        )
      SQL

      def migrate!
        conn = Record.connection
        conn.execute(VISITS_DDL)
        conn.execute(EVENTS_DDL)
      end
    end
  end
end
