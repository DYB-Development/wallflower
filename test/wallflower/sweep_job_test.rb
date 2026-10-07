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
end
