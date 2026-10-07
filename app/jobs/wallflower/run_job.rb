# frozen_string_literal: true

module Wallflower
  class RunJob < ActiveJob::Base
    def perform(task)
      task.update!(status: "running")
      Wallflower.kind(task.kind).runner.constantize.new.call(task)
      task.update!(status: "finished", finished_at: Time.current)
    end
  end
end
