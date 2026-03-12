# frozen_string_literal: true

module Libsql
  module Analytics
    module ControllerMethods
      extend ActiveSupport::Concern

      included do
        before_action :libsql_analytics_track_visit
      end

      private

      def libsql_analytics_track_visit
        return unless Libsql::Analytics.configured?
        return if libsql_analytics_skip?

        visit = Visit.track(
          request: request,
          visitor_id: libsql_analytics_visitor_id,
          account_identity: libsql_analytics_account_identity,
          metadata: libsql_analytics_metadata
        )
        @libsql_analytics_visit_id = visit.id
      rescue StandardError => e
        # analytics の障害がアプリに影響しないよう握り潰す
        Rails.logger.error("[libsql-analytics] track_visit failed: #{e.message}") if defined?(Rails)
      end

      def libsql_analytics_visitor_id
        two_years = 2 * 365 * 24 * 60 * 60
        cookies[Visit::COOKIE_NAME] ||= {
          value: Ulid.generate,
          expires: Time.now + two_years,
          httponly: true,
          secure: request.ssl?
        }
        cookies[Visit::COOKIE_NAME]
      end

      def libsql_analytics_account_identity
        config = Libsql::Analytics.configuration
        return nil unless config.account_identity.respond_to?(:call)

        config.account_identity.call(self)
      rescue StandardError
        nil
      end

      def libsql_analytics_metadata
        {
          ip: request.remote_ip,
          user_agent: request.user_agent
        }.compact
      end

      # assets / favicon など analytics 不要なリクエストをスキップ
      def libsql_analytics_skip?
        request.path.start_with?('/assets', '/favicon')
      end

      def track_event(name, properties = {})
        return unless Libsql::Analytics.configured?

        Event.track(
          name: name,
          visit_id: @libsql_analytics_visit_id,
          properties: properties
        )
      rescue StandardError => e
        Rails.logger.error("[libsql-analytics] track_event failed: #{e.message}") if defined?(Rails)
      end
    end
  end
end
