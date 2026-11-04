require "keystone_ui"
require "turbo-rails"
require "wallflower/version"
require "wallflower/configuration"
require "wallflower/task_types"
require "wallflower/engine"

module Wallflower
  def self.start(task_type:, person:, account: nil, params: {})
    Task.create!(task_type: task_type.to_s, person: person, account: account, params: params).tap { |task| RunJob.perform_later(task) }
  end
end
