# frozen_string_literal: true

module Wallflower
  Kind = Struct.new(:key, :title, :runner, keyword_init: true)

  class MissingRunner < StandardError; end

  def self.register_kind(key, title:, runner:)
    kinds[key.to_sym] = Kind.new(key: key.to_sym, title: title, runner: runner.to_s)
  end

  def self.kind(key)
    kinds.fetch(key.to_sym)
  end

  def self.kinds
    @kinds ||= {}
  end

  def self.check_kinds!
    kinds.each_value do |kind|
      next if kind.runner.safe_constantize

      raise MissingRunner, "Wallflower kind #{kind.key} names the runner #{kind.runner}, which does not exist."
    end
  end

  def self.reset_kinds!
    @kinds = {}
  end
end
