# frozen_string_literal: true

require "test_helper"

class Wallflower::RunJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

  class RaisingRunner
    def call(task)
      task.set_total(10)
      3.times { task.advance }
      raise ArgumentError, "Row 4 has no amount"
    end
  end

  class FailingTwiceRunner
    cattr_accessor :tries, default: 0

    def call(_task)
      self.class.tries += 1
      raise "Try #{self.class.tries} failed" if self.class.tries < 3
    end
  end

  class ManyRowsRunner
    def call(task)
      task.set_total(10_000)
      10_000.times { task.advance }
    end
  end

  def setup
    Wallflower.register_task_type(:export, title: "Export transactions", runner: RecordingRunner.name)
    Wallflower.register_task_type(:broken, title: "Broken export", runner: RaisingRunner.name)
  end

  def teardown
    Wallflower.reset_task_types!
    Wallflower.reset_configuration!
  end

  def person
    @person ||= User.create!(name: "Rep")
  end

  def account
    @account ||= Account.create!(name: "Team")
  end

  test "the job marks the task running and hands it to the runner with its parameters, person and account" do
    task = Wallflower::Task.create!(task_type: "export", person: person, account: account, params: { "month" => "2026-10" })

    Wallflower::RunJob.perform_now(task)

    assert_equal [ "running", { "month" => "2026-10" }, person, account ], RecordingRunner.seen
  end

  test "a runner sets the task's total and adds to its done count while it works" do
    Wallflower.register_task_type(:count, title: "Count rows", runner: CountingRunner.name)
    task = Wallflower::Task.create!(task_type: "count", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal [ 10, 3 ], task.reload.values_at(:total, :done)
  end

  test "a task whose runner returns is marked finished with the time it finished" do
    task = Wallflower::Task.create!(task_type: "export", person: person)

    travel_to(Time.utc(2026, 10, 7, 12, 0, 0)) { Wallflower::RunJob.perform_now(task) }

    assert_equal [ "finished", Time.utc(2026, 10, 7, 12, 0, 0) ], task.reload.values_at(:status, :finished_at)
  end

  test "the host's finish hook runs once with the task when it finishes" do
    finished = []
    Wallflower.configure { |config| config.on_finish = ->(task) { finished << task } }
    task = Wallflower::Task.create!(task_type: "export", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal [ task ], finished
  end

  test "a host that configures no finish hook still runs its task to the end" do
    task = Wallflower::Task.create!(task_type: "export", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal "finished", task.reload.status
  end

  test "a task whose runner raises is marked failed" do
    task = Wallflower::Task.create!(task_type: "broken", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal "failed", task.reload.status
  end

  test "a failed task keeps the error message its runner raised" do
    task = Wallflower::Task.create!(task_type: "broken", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal "Row 4 has no amount", task.reload.error_message
  end

  test "a runner's error is reported to the host's error reporting" do
    reported = []
    subscriber = Object.new
    subscriber.define_singleton_method(:report) { |error, **| reported << error.message }
    Rails.error.subscribe(subscriber)

    Wallflower::RunJob.perform_now(Wallflower::Task.create!(task_type: "broken", person: person))

    assert_equal [ "Row 4 has no amount" ], reported
  ensure
    Rails.error.unsubscribe(subscriber)
  end

  test "the host's finish hook runs once with the task when it fails" do
    called = []
    Wallflower.configure { |config| config.on_finish = ->(task) { called << task.status } }

    Wallflower::RunJob.perform_now(Wallflower::Task.create!(task_type: "broken", person: person))

    assert_equal [ "failed" ], called
  end

  test "a finish hook that raises leaves its finished task finished" do
    Wallflower.configure { |config| config.on_finish = ->(_task) { raise "Mail server is down" } }
    task = Wallflower::Task.create!(task_type: "export", person: person)

    begin
      Wallflower::RunJob.perform_now(task)
    rescue RuntimeError
      nil
    end

    assert_equal "finished", task.reload.status
  end

  test "the final done count is saved when a task finishes however recently progress was last saved" do
    Wallflower.register_task_type(:many, title: "Many rows", runner: ManyRowsRunner.name)
    task = Wallflower::Task.create!(task_type: "many", person: person)

    travel_to(Time.current) { Wallflower::RunJob.perform_now(task) }

    assert_equal 10_000, task.reload.done
  end

  test "a task whose runner raises records when it ended" do
    task = Wallflower::Task.create!(task_type: "broken", person: person)

    travel_to(Time.utc(2026, 10, 7, 12, 0, 0)) { Wallflower::RunJob.perform_now(task) }

    assert_equal Time.utc(2026, 10, 7, 12, 0, 0), task.reload.finished_at
  end

  test "a task records the time it started running" do
    task = Wallflower::Task.create!(task_type: "export", person: person)

    travel_to(Time.utc(2026, 10, 7, 12, 0, 0)) { Wallflower::RunJob.perform_now(task) }

    assert_equal Time.utc(2026, 10, 7, 12, 0, 0), task.reload.started_at
  end

  test "a task type with three tries finishes when a later try works" do
    FailingTwiceRunner.tries = 0
    Wallflower.register_task_type(:flaky, title: "Flaky", runner: FailingTwiceRunner.name, tries: 3)
    task = Wallflower::Task.create!(task_type: "flaky", person: person)

    perform_enqueued_jobs { Wallflower::RunJob.perform_later(task) }

    assert_equal [ "finished", 3 ], [ task.reload.status, FailingTwiceRunner.tries ]
  end

  test "a failed try runs again after the task type's retry wait" do
    freeze_time
    Wallflower.register_task_type(:flaky, title: "Flaky", runner: RaisingRunner.name, tries: 3, retry_wait: 60)
    task = Wallflower::Task.create!(task_type: "flaky", person: person)

    assert_enqueued_with(job: Wallflower::RunJob, at: 60.seconds.from_now) { Wallflower::RunJob.perform_now(task) }
  end

  test "a failed try with tries left stays running and does not run on_finish" do
    finished = []
    Wallflower.configure { |config| config.on_finish = ->(ended) { finished << ended } }
    Wallflower.register_task_type(:flaky, title: "Flaky", runner: RaisingRunner.name, tries: 3)
    task = Wallflower::Task.create!(task_type: "flaky", person: person)

    Wallflower::RunJob.perform_now(task)

    assert_equal [ "running", [] ], [ task.reload.status, finished ]
  end

  test "a new try starts its progress and refusals over" do
    Wallflower.register_task_type(:flaky, title: "Flaky", runner: RaisingRunner.name, tries: 2)
    task = Wallflower::Task.create!(task_type: "flaky", person: person)
    task.refuse(label: "Row 1", reason: "No amount")

    perform_enqueued_jobs { Wallflower::RunJob.perform_later(task) }

    assert_equal [ 3, 0 ], [ task.reload.done, task.refusals.count ]
  end
end
