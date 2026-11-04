# frozen_string_literal: true

require "test_helper"

class Wallflower::TaskTypesTest < ActiveSupport::TestCase
  def teardown
    Wallflower.reset_task_types!
  end

  test "a host registers a task type by its key, its title and the name of its runner class" do
    Wallflower.register_task_type(:export, title: "Export transactions", runner: "ExportRunner")

    assert_equal [ "Export transactions", "ExportRunner" ], [ Wallflower.task_type(:export).title, Wallflower.task_type(:export).runner ]
  end

  test "a task type whose runner class does not exist stops the app booting with a message naming the class" do
    Wallflower.register_task_type(:export, title: "Export transactions", runner: "MissingExportRunner")

    error = assert_raises(Wallflower::MissingRunner) { Wallflower.check_task_types! }

    assert_includes error.message, "MissingExportRunner"
  end
end
