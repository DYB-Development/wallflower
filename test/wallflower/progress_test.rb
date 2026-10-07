# frozen_string_literal: true

require "test_helper"

class Wallflower::ProgressTest < ActiveSupport::TestCase
  def task
    @task ||= Wallflower::Task.create!(kind: "export", person: User.create!(name: "Rep"), total: 10_000)
  end

  def progress_saves_while
    saves = 0
    counting = ->(*, payload) { saves += 1 if payload[:sql].start_with?("UPDATE") && payload[:sql].include?("wallflower_tasks") }
    ActiveSupport::Notifications.subscribed(counting, "sql.active_record") { yield }
    saves
  end

  test "reporting progress for 10,000 rows within one second saves at most one progress update" do
    task
    travel_to(Time.current) do
      assert_operator progress_saves_while { 10_000.times { task.advance } }, :<=, 1
    end
  end
end
