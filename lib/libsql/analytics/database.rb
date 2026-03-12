# frozen_string_literal: true

module Libsql
  module Analytics
    class Database
      def initialize(config)
        @config = config
        @conn = nil
        @database = nil
      end

      def connection
        @conn ||= connect!
      end

      # INSERT / UPDATE / DELETE — ? プレースホルダーを値に展開して execute
      # execute_with_params は Vec<String> のため nil を渡せない。
      # nil → NULL、文字列 → シングルクォートエスケープして SQL に直接展開する。
      def execute(sql, params = [])
        expanded = params.empty? ? sql : expand_params(sql, params)
        connection.execute(expanded)
      end

      # SELECT — パラメータなし（libsql の query は params 非対応）
      def query(sql)
        connection.query(sql)
      end

      def sync
        @database&.sync
      end

      private

      # ? プレースホルダーを値に展開する
      def expand_params(sql, params)
        i = -1
        sql.gsub('?') do
          i += 1
          v = params[i]
          v.nil? ? 'NULL' : "'#{v.to_s.gsub("'", "''")}'"
        end
      end

      def connect!
        require 'turso_libsql'

        storage_dir = File.dirname(@config.replica_path)
        FileUtils.mkdir_p(storage_dir) unless File.directory?(storage_dir)

        @database = TursoLibsql::Database.new_remote_replica(
          @config.replica_path.to_s,
          @config.url.to_s,
          @config.token.to_s,
          @config.sync_interval.to_i
        )
        @database.connect
      end
    end
  end
end
