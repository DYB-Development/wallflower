# frozen_string_literal: true

require "test_helper"

class TaskPageTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    Wallflower.register_kind(:export, title: "Export transactions", runner: "Object")
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    Wallflower.reset_kinds!
  end

  def task(**attributes)
    @task ||= Wallflower::Task.create!(kind: "export", person: person, **attributes)
  end

  test "the person who started a task sees its kind's title on its page" do
    get "/background/tasks/#{task.id}"

    assert_select "h1", text: "Export transactions"
  end

  test "the person who started a task sees its status on its page" do
    get "/background/tasks/#{task(status: "running").id}"

    assert_select "#status_task_#{task.id}", text: "Running"
  end

  test "the person who started a task sees a progress bar of done against total on its page" do
    get "/background/tasks/#{task(total: 10, done: 3).id}"

    assert_select "#progress_task_#{task.id} [role=progressbar], #progress_task_#{task.id}", text: /3 of 10/
  end

  test "someone other than the person who started a task gets a not-found response for its page" do
    started = task
    ApplicationController.signed_in_user = User.create!(name: "Teammate")

    get "/background/tasks/#{started.id}"

    assert_response :not_found
  end
end
