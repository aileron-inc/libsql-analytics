# frozen_string_literal: true

module Libsql
  module Analytics
    class Railtie < Rails::Railtie
      initializer 'libsql_analytics.include_controller_methods' do
        ActiveSupport.on_load(:action_controller_base) do
          include Libsql::Analytics::ControllerMethods
        end
      end

      config.after_initialize do
        next unless Libsql::Analytics.configured?

        Libsql::Analytics::Migrator.new(Libsql::Analytics.db).migrate!
      end
    end
  end
end
