# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Wallflower
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../install/templates", __dir__)

      desc "Updates Wallflower: copies the migrations and the Stimulus controller added since it was installed."

      def copy_refusals_migration
        migration_template "create_wallflower_refusals.rb.erb", "db/migrate/create_wallflower_refusals.rb"
      end

      def copy_result_url_migration
        migration_template "add_result_url_to_wallflower_tasks.rb.erb", "db/migrate/add_result_url_to_wallflower_tasks.rb"
      end

      def copy_error_message_migration
        migration_template "add_error_message_to_wallflower_tasks.rb.erb", "db/migrate/add_error_message_to_wallflower_tasks.rb"
      end

      def copy_catch_up_controller
        source = File.expand_path("../../../../app/javascript/wallflower/catch_up_controller.js", __dir__)
        create_file "app/javascript/controllers/wallflower/catch_up_controller.js", File.read(source)
      end
    end
  end
end
