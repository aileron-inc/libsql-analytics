# frozen_string_literal: true

require 'json'

module Libsql
  module Analytics
    class Event
      def initialize(db)
        @db = db
      end

      def track(name:, visit_id: nil, properties: {})
        id = Ulid.generate

        @db.execute(
          <<~SQL,
            INSERT INTO libsql_analytics_events
              (id, visit_id, name, properties, event_at)
            VALUES (?, ?, ?, ?, ?)
          SQL
          [
            id,
            visit_id,
            name,
            properties.empty? ? nil : JSON.generate(properties),
            Time.now.utc.iso8601
          ]
        )

        id
      end
    end
  end
end
