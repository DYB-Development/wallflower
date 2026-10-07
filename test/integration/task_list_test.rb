# frozen_string_literal: true

require "test_helper"

class TaskListTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    Wallflower.register_kind(:export, title: "Export transactions", runner: "Object")
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    Wallflower.reset_kinds!
    Wallflower.reset_configuration!
  end

  def started(at:, **attributes)
    Wallflower::Task.create!(kind: "export", person: person, created_at: at, **attributes)
  end

  test "a person sees the tasks they started, newest first, each linking to its page" do
    older = started(at: 2.days.ago)
    newer = started(at: 1.day.ago)

    get "/background"

    assert_equal [ "/background/tasks/#{newer.id}", "/background/tasks/#{older.id}" ], css_select("[data-task-row] a").map { |link| link["href"] }
  end

  test "each row shows the kind's title, the status, the progress and when it was started" do
    started(at: Time.utc(2026, 10, 7, 9, 30), status: "running", total: 10, done: 3)

    get "/background"

    assert_select "[data-task-row]", text: /Export transactions.*Running.*3 of 10.*Started Oct 7, 2026/m
  end

  test "each row of the task list listens for changes to its task" do
    started(at: 2.days.ago)
    started(at: 1.day.ago)

    get "/background"

    assert_select "[data-task-row] turbo-cable-stream-source", count: 2
  end

  test "the list shows no task started by another person" do
    Wallflower::Task.create!(kind: "export", person: User.create!(name: "Teammate"))

    get "/background"

    assert_select "[data-task-row]", count: 0
  end
end
