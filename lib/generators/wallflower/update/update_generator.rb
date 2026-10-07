# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Wallflower
  module Generators
    class UpdateGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("../install/templates", __dir__)

      desc "Updates Wallflower: copies the migrations added since it was installed."

      def copy_refusals_migration
        migration_template "create_wallflower_refusals.rb.erb", "db/migrate/create_wallflower_refusals.rb"
      end
    end
  end
end
