# frozen_string_literal: true

require "test_helper"

class Wallflower::SweepJobTest < ActiveSupport::TestCase
  def teardown
    Wallflower.reset_configuration!
  end

  def running_since(time)
    Wallflower::Task.create!(kind: "export", person: User.create!(name: "Rep"), status: "running", updated_at: time)
  end

  test "marks a task failed when it has been running without an update past the limit" do
    task = running_since(2.hours.ago)

    Wallflower::SweepJob.perform_now

    assert_equal "failed", task.reload.status
  end

  test "gives a stalled task a reason saying it stalled" do
    task = running_since(2.hours.ago)

    Wallflower::SweepJob.perform_now

    assert_equal "Stalled: no progress for 1 hour", task.reload.error_message
  end

  test "leaves a running task that was updated within the limit running" do
    task = running_since(10.minutes.ago)

    Wallflower::SweepJob.perform_now

    assert_equal "running", task.reload.status
  end
end
