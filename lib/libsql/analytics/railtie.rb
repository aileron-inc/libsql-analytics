# frozen_string_literal: true

module Libsql
  module Analytics
    class Railtie < Rails::Railtie
      initializer 'libsql_analytics.setup' do
        ActiveSupport.on_load(:action_controller_base) do
          include Libsql::Analytics::ControllerMethods
        end
      end

      initializer 'libsql_analytics.migrate' do
        next unless Libsql::Analytics.configured?

        Libsql::Analytics::Migrator.new(Libsql::Analytics.db).migrate!
      end
    end
  end
end
