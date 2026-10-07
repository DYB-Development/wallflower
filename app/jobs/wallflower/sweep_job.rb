# frozen_string_literal: true

module Wallflower
  class SweepJob < ActiveJob::Base
    def perform
      Task.where(status: "running").where(updated_at: ...Wallflower.configuration.stall_after.ago).find_each do |task|
        task.update!(status: "failed", error_message: "Stalled: no progress for #{Wallflower.configuration.stall_after.inspect}")
      end
    end
  end
end
