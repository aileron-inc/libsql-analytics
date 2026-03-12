# frozen_string_literal: true

require 'securerandom'
require 'fileutils'
require 'active_record'
require 'active_record/connection_adapters/libsql_adapter'

require_relative 'analytics/version'
require_relative 'analytics/configuration'
require_relative 'analytics/ulid'
require_relative 'analytics/record'
require_relative 'analytics/migrator'
require_relative 'analytics/visit'
require_relative 'analytics/event'

module Libsql
  module Analytics
    class Error < StandardError; end

    class << self
      def configure
        yield configuration
        establish_connection!
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configured?
        !configuration.url.nil?
      end

      private

      def establish_connection!
        configuration.validate!

        # replica_path の親ディレクトリを作成
        storage_dir = File.dirname(configuration.replica_path)
        FileUtils.mkdir_p(storage_dir) unless File.directory?(storage_dir)

        Record.establish_connection(
          adapter: 'turso',
          database: configuration.url,
          token: configuration.token.to_s,
          replica_path: configuration.replica_path,
          sync_interval: configuration.sync_interval.to_i
        )
      end
    end
  end
end

require_relative 'analytics/controller_methods' if defined?(ActiveSupport::Concern)
require_relative 'analytics/railtie' if defined?(Rails)
