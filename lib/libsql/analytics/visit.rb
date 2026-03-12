# frozen_string_literal: true

require 'json'
require 'uri'

module Libsql
  module Analytics
    class Visit < Record
      self.table_name = 'libsql_analytics_visits'

      COOKIE_NAME = 'libsql_analytics_visitor'

      before_create :assign_ulid

      # request オブジェクトから visit を記録する
      def self.track(request:, visitor_id:, account_identity: nil, metadata: {})
        uri = parse_uri(request.url)
        query = uri&.query

        create!(
          visitor_id: visitor_id,
          account_identity: account_identity,
          referrer: request.referer,
          host: uri&.host,
          url: request.url,
          path: uri&.path,
          query: query,
          query_params: parse_query_params(query),
          metadata: metadata.empty? ? nil : metadata.to_json,
          started_at: Time.now.utc.iso8601
        )
      end

      private

      def assign_ulid
        self.id ||= Ulid.generate
      end

      def self.parse_uri(url)
        URI.parse(url)
      rescue URI::InvalidURIError
        nil
      end

      def self.parse_query_params(query)
        return nil if query.nil? || query.empty?

        URI.decode_www_form(query).to_h.to_json
      rescue StandardError
        nil
      end
    end
  end
end
