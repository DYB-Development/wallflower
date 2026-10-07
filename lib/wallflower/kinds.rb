# frozen_string_literal: true

module Wallflower
  Kind = Struct.new(:key, :title, :runner, keyword_init: true)

  def self.register_kind(key, title:, runner:)
    kinds[key.to_sym] = Kind.new(key: key.to_sym, title: title, runner: runner.to_s)
  end

  def self.kind(key)
    kinds.fetch(key.to_sym)
  end

  def self.kinds
    @kinds ||= {}
  end

  def self.reset_kinds!
    @kinds = {}
  end
end
