# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Wallflower
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs Wallflower: copies its migration."

      def copy_migration
        migration_template "create_wallflower_tasks.rb.erb", "db/migrate/create_wallflower_tasks.rb"
      end
    end
  end
end
