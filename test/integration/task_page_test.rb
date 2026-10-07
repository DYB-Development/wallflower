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

  test "a finished task's page shows how many rows were changed and how many were refused" do
    task(status: "finished", total: 3, done: 3).refuse(label: "Row 2", reason: "Amount is missing")

    get "/background/tasks/#{task.id}"

    assert_select "#outcome_task_#{task.id}", text: "2 changed, 1 refused"
  end

  test "a finished task's page lists each refused row with its reason" do
    task(status: "finished", total: 3, done: 3)
    task.refuse(label: "Row 2", reason: "Amount is missing")
    task.refuse(label: "Row 3", reason: "Date is not a date")

    get "/background/tasks/#{task.id}"

    assert_equal [ [ "Row 2", "Amount is missing" ], [ "Row 3", "Date is not a date" ] ], css_select("#refusals_task_#{task.id} tbody tr").map { |row| row.css("td").map { |cell| cell.text.strip } }
  end

  test "a finished task that refused no rows shows no list of refused rows" do
    get "/background/tasks/#{task(status: "finished", total: 3, done: 3).id}"

    assert_select "#refusals_task_#{task.id}", count: 0
  end

  test "a finished task's page offers the link to its report" do
    task(status: "finished").link_result("/console/reports/42")

    get "/background/tasks/#{task.id}"

    assert_select "a[href=?]", "/console/reports/42", text: "Open report"
  end

  test "a failed task's page shows the error message" do
    get "/background/tasks/#{task(status: "failed", error_message: "Row 4 has no amount").id}"

    assert_select "#error_task_#{task.id}", text: "Row 4 has no amount"
  end

  test "a failed task's page shows how far it got before it failed" do
    get "/background/tasks/#{task(status: "failed", error_message: "Row 4 has no amount", total: 10, done: 3).id}"

    assert_select "#progress_task_#{task.id}", text: /3 of 10/
  end

  test "a finished task shows its status in a success badge" do
    get "/background/tasks/#{task(status: "finished").id}"

    assert_select "#status_task_#{task.id} .ks-badge-success", text: "Finished"
  end

  test "a failed task shows its status in a danger badge" do
    get "/background/tasks/#{task(status: "failed").id}"

    assert_select "#status_task_#{task.id} .ks-badge-danger", text: "Failed"
  end
end
