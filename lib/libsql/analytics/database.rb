# frozen_string_literal: true

module Libsql
  module Analytics
    class Database
      def initialize(config)
        @config = config
        @connection = nil
        @database = nil
      end

      def connection
        @connection ||= connect!
      end

      def execute(sql, params = [])
        connection.execute(sql, params)
      end

      def query(sql, params = [])
        connection.query(sql, params)
      end

      def sync
        @database&.sync
      end

      private

      def connect!
        require 'turso_libsql'

        storage_dir = File.dirname(@config.replica_path)
        FileUtils.mkdir_p(storage_dir) unless File.directory?(storage_dir)

        @database = TursoLibsql::Database.new_remote_replica(
          @config.replica_path,
          @config.url,
          @config.token.to_s,
          @config.sync_interval
        )
        @database.connect
      end
    end
  end
end
