# frozen_string_literal: true

require "test_helper"

class Wallflower::TimeLeftTest < ActiveSupport::TestCase
  def task(**attributes)
    Wallflower::Task.create!(kind: "import", person: User.create!(name: "Rep"), status: "running", **attributes)
  end

  test "a running task works out the seconds left from how fast it has gone so far" do
    travel_to(Time.utc(2026, 10, 7, 12, 1, 0)) do
      assert_equal 180, task(total: 100, done: 25, started_at: Time.utc(2026, 10, 7, 12, 0, 0)).seconds_left
    end
  end

  test "a task with no total has no seconds left" do
    assert_nil task(done: 25, started_at: 1.minute.ago).seconds_left
  end

  test "a task under five percent of the way through has no seconds left yet" do
    assert_nil task(total: 100, done: 4, started_at: 1.minute.ago).seconds_left
  end

  test "a finished task has no seconds left" do
    assert_nil task(status: "finished", total: 100, done: 25, started_at: 1.minute.ago).seconds_left
  end

  test "a failed task has no seconds left" do
    assert_nil task(status: "failed", total: 100, done: 25, started_at: 1.minute.ago).seconds_left
  end
end
