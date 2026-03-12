# frozen_string_literal: true

module Libsql
  module Analytics
    class Configuration
      attr_accessor :url,
                    :token,
                    :replica_path,
                    :sync_interval,
                    :account_identity,
                    :skip_paths

      def initialize
        @url = nil
        @token = nil
        @replica_path = 'storage/analytics.db'
        @sync_interval = 60
        @account_identity = nil
        @skip_paths = ['/assets', '/favicon']
      end

      def validate!
        raise ArgumentError, 'Libsql::Analytics url is required' if url.nil?
        raise ArgumentError, 'Libsql::Analytics replica_path is required' if replica_path.nil?
      end
    end
  end
end
