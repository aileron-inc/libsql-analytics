# frozen_string_literal: true

require 'json'
require 'uri'

module Libsql
  module Analytics
    class Visit
      COOKIE_NAME = 'libsql_analytics_visitor'

      attr_reader :id

      def initialize(db)
        @db = db
        @id = Ulid.generate
      end

      def track(request:, visitor_id:, account_identity: nil, metadata: {})
        uri = parse_uri(request.url)

        @db.execute(
          <<~SQL,
            INSERT INTO libsql_analytics_visits
              (id, visitor_id, account_identity, referrer, host, url, path, query, query_params, metadata, started_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL
          [
            @id,
            visitor_id,
            account_identity,
            request.referer,
            uri&.host,
            request.url,
            uri&.path,
            uri&.query,
            parse_query_params(uri&.query),
            metadata.empty? ? nil : JSON.generate(metadata),
            Time.now.utc.iso8601
          ]
        )

        @id
      end

      private

      def parse_uri(url)
        URI.parse(url)
      rescue URI::InvalidURIError
        nil
      end

      def parse_query_params(query)
        return nil if query.nil? || query.empty?

        params = URI.decode_www_form(query).to_h
        JSON.generate(params)
      rescue StandardError
        nil
      end
    end
  end
end
