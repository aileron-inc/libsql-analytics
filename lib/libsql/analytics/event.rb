# frozen_string_literal: true

require 'json'

module Libsql
  module Analytics
    class Event < Record
      self.table_name = 'libsql_analytics_events'

      before_create :assign_ulid

      # イベントを記録する
      def self.track(name:, visit_id: nil, properties: {})
        create!(
          visit_id: visit_id,
          name: name,
          properties: properties.empty? ? nil : properties.to_json,
          event_at: Time.now.utc.iso8601
        )
      end

      private

      def assign_ulid
        self.id ||= Ulid.generate
      end
    end
  end
end
