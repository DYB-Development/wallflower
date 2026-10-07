require "keystone_ui"
require "wallflower/version"
require "wallflower/configuration"
require "wallflower/kinds"
require "wallflower/engine"

module Wallflower
  def self.start(kind:, person:, account: nil, params: {})
    Task.create!(kind: kind.to_s, person: person, account: account, params: params).tap { |task| RunJob.perform_later(task) }
  end
end
