# frozen_string_literal: true

require "test_helper"
require "turbo/broadcastable/test_helper"

class Wallflower::TaskBroadcastTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  def setup
    Wallflower.register_kind(:export, title: "Export transactions", runner: "Object")
  end

  def teardown
    Wallflower.reset_kinds!
  end

  test "a change to a task sends its open page the new status and progress" do
    task = Wallflower::Task.create!(kind: "export", person: User.create!(name: "Rep"), total: 10)

    broadcasts = capture_turbo_stream_broadcasts(task) { task.advance(3) }

    assert_includes broadcasts.last.to_html, "3 of 10"
  end
end
