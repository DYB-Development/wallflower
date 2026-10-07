# frozen_string_literal: true

module Wallflower
  class SweepJob < ActiveJob::Base
    def perform
      fail_stalled
      delete_old
    end

    private

    def delete_old
      keep_for = Wallflower.configuration.keep_for
      return unless keep_for

      Task.where(status: %w[finished failed]).where(finished_at: ...keep_for.ago).find_each(&:destroy!)
    end

    def fail_stalled
      Task.where(status: "running").where(updated_at: ...Wallflower.configuration.stall_after.ago).find_each do |task|
        task.update!(status: "failed", error_message: "Stalled: no progress for #{Wallflower.configuration.stall_after.inspect}")
        Wallflower.configuration.on_finish&.call(task)
      end
    end
  end
end
