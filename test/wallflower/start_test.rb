# frozen_string_literal: true

require "test_helper"

class Wallflower::StartTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  test "starting a task returns it queued" do
    task = Wallflower.start(kind: :export, person: person, params: { "month" => "2026-10" })

    assert_equal "queued", task.status
  end

  test "starting a task enqueues the job that runs it" do
    task = nil

    assert_enqueued_with(job: Wallflower::RunJob) { task = Wallflower.start(kind: :export, person: person) }
  end

  test "starting a task keeps the kind, account and parameters it was given" do
    account = Account.create!(name: "Team")

    task = Wallflower.start(kind: :export, person: person, account: account, params: { "month" => "2026-10" })

    assert_equal [ "export", account, { "month" => "2026-10" } ], [ task.reload.kind, task.account, task.params ]
  end
end
