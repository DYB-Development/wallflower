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

  private

  def migration
    File.read(Dir.glob("#{destination}/db/migrate/*_create_wallflower_tasks.rb").first.to_s)
  end
end
