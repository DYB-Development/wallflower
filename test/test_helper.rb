# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end

  create_table :accounts, force: true do |t|
    t.string :name
  end
end

ActiveRecord::Migration.verbose = false
install_migration = File.expand_path("../lib/generators/wallflower/install/templates/create_wallflower_tasks.rb.erb", __dir__)
eval(ERB.new(File.read(install_migration)).result) # rubocop:disable Security/Eval
CreateWallflowerTasks.migrate(:up)

Rails.application.config.action_dispatch.show_exceptions = :none
