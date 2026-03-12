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

        visitor_id = libsql_analytics_visitor_id
        account_identity = libsql_analytics_account_identity
        metadata = libsql_analytics_metadata

        visit = Libsql::Analytics::Visit.new(Libsql::Analytics.db)
        visit_id = visit.track(
          request: request,
          visitor_id: visitor_id,
          account_identity: account_identity,
          metadata: metadata
        )

        @libsql_analytics_visit_id = visit_id
      end

      def libsql_analytics_visitor_id
        two_years = 2 * 365 * 24 * 60 * 60
        cookies[Visit::COOKIE_NAME] ||= {
          value: Ulid.generate,
          expires: Time.now + two_years,
          httponly: true
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

      def track_event(name, properties = {})
        return unless Libsql::Analytics.configured?

        event = Libsql::Analytics::Event.new(Libsql::Analytics.db)
        event.track(
          name: name,
          visit_id: @libsql_analytics_visit_id,
          properties: properties
        )
      end
    end
  end
end
