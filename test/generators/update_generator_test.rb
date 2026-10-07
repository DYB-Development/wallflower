# frozen_string_literal: true

require "test_helper"
require "rails/generators"
require "generators/wallflower/update/update_generator"

class Wallflower::Generators::UpdateGeneratorTest < ActiveSupport::TestCase
  def destination
    @destination ||= File.expand_path("../../tmp/update_generator_test", __dir__)
  end

  def setup
    FileUtils.mkdir_p("#{destination}/db/migrate")
    File.write("#{destination}/db/migrate/20261007000000_create_wallflower_tasks.rb", "")
  end

  def teardown
    FileUtils.rm_rf(destination)
  end

  def update
    Rails::Generators.invoke("wallflower:update", [], destination_root: destination, quiet: true)
  end

  def migrations_named(name)
    Dir.glob("#{destination}/db/migrate/*_#{name}.rb")
  end

  test "adds the refusals table to an app that installed earlier" do
    update

    assert_equal 1, migrations_named("create_wallflower_refusals").size
  end

  test "adds nothing the app already has when it runs again" do
    update
    update

    assert_equal 1, migrations_named("create_wallflower_refusals").size
  end
end
