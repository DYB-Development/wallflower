# frozen_string_literal: true

module Wallflower
  class RunJob < ActiveJob::Base
    def perform(task)
      run(task)
      Wallflower.configuration.on_finish&.call(task)
    end

    private

    def run(task)
      task.update!(status: "running")
      Wallflower.kind(task.kind).runner.constantize.new.call(task)
      task.update!(status: "finished", finished_at: Time.current)
    rescue StandardError => error
      task.update!(status: "failed", error_message: error.message)
      Rails.error.report(error, handled: true, context: { wallflower_task_id: task.id })
    end
  end
end
