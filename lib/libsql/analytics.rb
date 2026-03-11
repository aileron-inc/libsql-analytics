# frozen_string_literal: true

require 'securerandom'
require 'fileutils'

require_relative 'analytics/version'
require_relative 'analytics/configuration'
require_relative 'analytics/ulid'
require_relative 'analytics/database'
require_relative 'analytics/migrator'
require_relative 'analytics/visit'
require_relative 'analytics/event'

module Libsql
  module Analytics
    class Error < StandardError; end

    class << self
      def configure
        yield configuration
        @db = nil # 設定変更時は接続をリセット
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configured?
        !configuration.url.nil?
      end

      def db
        @db ||= begin
          configuration.validate!
          db = Database.new(configuration)
          db.connection # 接続確立
          db
        end
      end
    end
  end
end

require_relative 'analytics/controller_methods'
require_relative 'analytics/railtie' if defined?(Rails)
