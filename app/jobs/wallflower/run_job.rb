# frozen_string_literal: true

module Wallflower
  class RunJob < ActiveJob::Base
    def perform(task)
      task.update!(status: "running")
      Wallflower.kind(task.kind).runner.constantize.new.call(task)
      task.update!(status: "finished", finished_at: Time.current)
      Wallflower.configuration.on_finish&.call(task)
    rescue StandardError
      task.update!(status: "failed")
    end
  end
end
