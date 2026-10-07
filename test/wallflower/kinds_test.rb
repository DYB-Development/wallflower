# frozen_string_literal: true

require "test_helper"

class Wallflower::KindsTest < ActiveSupport::TestCase
  def teardown
    Wallflower.reset_kinds!
  end

  test "a host registers a kind by its key, its title and the name of its runner class" do
    Wallflower.register_kind(:export, title: "Export transactions", runner: "ExportRunner")

    assert_equal [ "Export transactions", "ExportRunner" ], [ Wallflower.kind(:export).title, Wallflower.kind(:export).runner ]
  end

  test "a kind whose runner class does not exist stops the app booting with a message naming the class" do
    Wallflower.register_kind(:export, title: "Export transactions", runner: "MissingExportRunner")

    error = assert_raises(Wallflower::MissingRunner) { Wallflower.check_kinds! }

    assert_includes error.message, "MissingExportRunner"
  end
end
