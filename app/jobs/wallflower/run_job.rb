# frozen_string_literal: true

module Wallflower
  class RunJob < ActiveJob::Base
    def perform(task)
      run(task)
      Wallflower.configuration.on_finish&.call(task)
    end

    private

    def run(task)
      task.update!(status: "running", started_at: Time.current)
      Wallflower.kind(task.kind).runner.constantize.new.call(task)
      task.update!(status: "finished", finished_at: Time.current)
    rescue StandardError => error
      return retry_job if executions < Wallflower.kind(task.kind).tries

      task.update!(status: "failed", error_message: error.message, finished_at: Time.current)
      Rails.error.report(error, handled: true, context: { wallflower_task_id: task.id })
    end
  end
end
