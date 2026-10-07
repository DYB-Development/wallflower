# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Wallflower
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs Wallflower: copies its migrations and its Stimulus controller."

      def copy_migration
        migration_template "create_wallflower_tasks.rb.erb", "db/migrate/create_wallflower_tasks.rb"
        migration_template "create_wallflower_refusals.rb.erb", "db/migrate/create_wallflower_refusals.rb"
        migration_template "add_result_url_to_wallflower_tasks.rb.erb", "db/migrate/add_result_url_to_wallflower_tasks.rb"
        migration_template "add_error_message_to_wallflower_tasks.rb.erb", "db/migrate/add_error_message_to_wallflower_tasks.rb"
      end

      def copy_catch_up_controller
        source = File.expand_path("../../../../app/javascript/wallflower/catch_up_controller.js", __dir__)
        create_file "app/javascript/controllers/wallflower/catch_up_controller.js", File.read(source)
      end
    end
  end
end
