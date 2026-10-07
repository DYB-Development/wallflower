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
end
