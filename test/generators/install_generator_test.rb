# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/wallflower/install/install_generator"

class Wallflower::Generators::InstallGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/install_generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p(destination)
    Rails::Generators.invoke("wallflower:install", [], destination_root: destination, quiet: true)
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  test "copies a migration that creates the tasks table" do
    assert_includes migration, "create_table :wallflower_tasks"
  end

  test "the migration gives each task the person who started it" do
    assert_includes migration, "t.references :person, polymorphic: true, null: false"
  end

  test "the migration lets a task belong to an account" do
    assert_includes migration, "t.references :account, polymorphic: true, null: true"
  end

  test "copies a migration that creates the refusals table" do
    assert_includes File.read(Dir.glob("#{destination}/db/migrate/*_create_wallflower_refusals.rb").first.to_s), "create_table :wallflower_refusals"
  end

  test "copies a migration that gives each task a result link" do
    assert_includes File.read(Dir.glob("#{destination}/db/migrate/*_add_result_url_to_wallflower_tasks.rb").first.to_s), "add_column :wallflower_tasks, :result_url, :string"
  end

  test "copies a migration that gives each task an error message" do
    assert_includes File.read(Dir.glob("#{destination}/db/migrate/*_add_error_message_to_wallflower_tasks.rb").first.to_s), "add_column :wallflower_tasks, :error_message, :text"
  end

  test "copies the controller that catches a task page up when it is shown again" do
    assert_equal File.read(File.expand_path("../../app/javascript/wallflower/catch_up_controller.js", __dir__)),
                 File.read("#{destination}/app/javascript/controllers/wallflower/catch_up_controller.js")
  end

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_wallflower_tasks.rb").first.to_s)
  end
end
