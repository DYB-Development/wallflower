# frozen_string_literal: true

require "test_helper"

class Wallflower::SweepJobTest < ActiveSupport::TestCase
  def teardown
    Wallflower.reset_configuration!
  end

  def ended(status, at:)
    Wallflower::Task.create!(kind: "export", person: User.create!(name: "Rep"), status: status, finished_at: at)
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

  test "uses the stall limit the host sets" do
    Wallflower.configure { |config| config.stall_after = 10.minutes }
    task = running_since(20.minutes.ago)

    Wallflower::SweepJob.perform_now

    assert_equal "failed", task.reload.status
  end

  test "runs the host's finish hook once with a task it marks stalled" do
    called = []
    Wallflower.configure { |config| config.on_finish = ->(task) { called << task.error_message } }
    running_since(2.hours.ago)

    Wallflower::SweepJob.perform_now

    assert_equal [ "Stalled: no progress for 1 hour" ], called
  end

  test "with a keep period set, deletes a task that finished longer ago than the period" do
    Wallflower.configure { |config| config.keep_for = 30.days }
    task = ended("finished", at: 31.days.ago)

    Wallflower::SweepJob.perform_now

    assert_not Wallflower::Task.exists?(task.id)
  end

  test "with a keep period set, deletes a task that failed longer ago than the period" do
    Wallflower.configure { |config| config.keep_for = 30.days }
    task = ended("failed", at: 31.days.ago)

    Wallflower::SweepJob.perform_now

    assert_not Wallflower::Task.exists?(task.id)
  end

  test "records when a stalled task ended" do
    task = nil
    travel_to(Time.utc(2026, 10, 7, 12, 0, 0)) do
      task = running_since(2.hours.ago)
      Wallflower::SweepJob.perform_now
    end

    assert_equal Time.utc(2026, 10, 7, 12, 0, 0), task.reload.finished_at
  end
end
