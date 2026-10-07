# frozen_string_literal: true

require "test_helper"

class Wallflower::RunJobTest < ActiveSupport::TestCase
  class RecordingRunner
    cattr_accessor :seen

    def call(task)
      self.class.seen = [ task.status, task.params, task.person, task.account ]
    end
  end

  class CountingRunner
    def call(task)
      task.set_total(10)
      3.times { task.advance }
    end
  end

  def setup
    Wallflower.register_kind(:export, title: "Export transactions", runner: RecordingRunner.name)
  end

  def teardown
    Wallflower.reset_kinds!
    Wallflower.reset_configuration!
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

  test "a runner sets the task's total and adds to its done count while it works" do
    Wallflower.register_kind(:count, title: "Count rows", runner: CountingRunner.name)
    task = Wallflower::Task.create!(kind: "count", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal [ 10, 3 ], task.reload.values_at(:total, :done)
  end

  test "a task whose runner returns is marked finished with the time it finished" do
    task = Wallflower::Task.create!(kind: "export", person: person)

    travel_to(Time.utc(2026, 10, 7, 12, 0, 0)) { Wallflower::RunJob.perform_now(task) }

    assert_equal [ "finished", Time.utc(2026, 10, 7, 12, 0, 0) ], task.reload.values_at(:status, :finished_at)
  end

  test "the host's finish hook runs once with the task when it finishes" do
    finished = []
    Wallflower.configure { |config| config.on_finish = ->(task) { finished << task } }
    task = Wallflower::Task.create!(kind: "export", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal [ task ], finished
  end

  test "a host that configures no finish hook still runs its task to the end" do
    task = Wallflower::Task.create!(kind: "export", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal "finished", task.reload.status
  end
end
