# frozen_string_literal: true

require "test_helper"

class Wallflower::RunJobTest < ActiveSupport::TestCase
  class RecordingRunner
    cattr_accessor :seen

    def call(task)
      self.class.seen = [ task.status, task.params, task.person, task.account ]
    end
  end

  def setup
    Wallflower.register_kind(:export, title: "Export transactions", runner: RecordingRunner.name)
  end

  def teardown
    Wallflower.reset_kinds!
  end

  def person
    @person ||= User.create!(name: "Rep")
  end

  def account
    @account ||= Account.create!(name: "Team")
  end

  test "the job marks the task running and hands it to the runner with its parameters, person and account" do
    task = Wallflower::Task.create!(kind: "export", person: person, account: account, params: { "month" => "2026-10" })

    Wallflower::RunJob.perform_now(task)

    assert_equal [ "running", { "month" => "2026-10" }, person, account ], RecordingRunner.seen
  end
end
