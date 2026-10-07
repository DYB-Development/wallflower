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
    ApplicationController.signed_in_account = nil
    Wallflower.reset_kinds!
    Wallflower.reset_configuration!
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

    assert_select "#progress_task_#{task.id}", text: /3 of 10/
  end

  test "someone other than the person who started a task gets a not-found response for its page" do
    started = task
    ApplicationController.signed_in_user = User.create!(name: "Teammate")

    get "/background/tasks/#{started.id}"

    assert_response :not_found
  end

  test "the person who started a task gets a not-found response for its page when viewing from another account" do
    Wallflower.configure { |config| config.current_account_method = :current_account }
    started = task(account: Account.create!(name: "Team"))
    ApplicationController.signed_in_account = Account.create!(name: "Other team")

    get "/background/tasks/#{started.id}"

    assert_response :not_found
  end

  test "an open task page listens for changes to its task" do
    get "/background/tasks/#{task.id}"

    assert_select "turbo-cable-stream-source"
  end

  test "a task page opened in the Hotwire Native iOS app shows the same status and progress as in a browser" do
    get "/background/tasks/#{task(status: "running", total: 10, done: 3).id}", headers: { "User-Agent" => "Mozilla/5.0 (iPhone) Turbo Native iOS" }

    assert_select "#live_task_#{task.id}", text: /Running.*3 of 10/m
  end

  test "a task whose total is not known yet shows no progress bar" do
    get "/background/tasks/#{task.id}"

    assert_select "#progress_task_#{task.id} *", count: 0
  end

  test "a finished task's page offers a download of its file" do
    task(status: "finished").attach_result(io: StringIO.new("a,b\n"), filename: "transactions.csv")

    get "/background/tasks/#{task.id}"

    assert_select "a[href=?]", "/background/tasks/#{task.id}/download", text: "Download"
  end

  test "the person who started a task receives its file when they follow the download" do
    task(status: "finished").attach_result(io: StringIO.new("month,total\n2026-10,42\n"), filename: "transactions.csv")

    get "/background/tasks/#{task.id}/download"

    assert_equal "month,total\n2026-10,42\n", response.body
  end

  test "anyone else following a task's download link gets a not-found response" do
    task(status: "finished").attach_result(io: StringIO.new("a,b\n"), filename: "transactions.csv")
    ApplicationController.signed_in_user = User.create!(name: "Teammate")

    get "/background/tasks/#{task.id}/download"

    assert_response :not_found
  end
end
