# frozen_string_literal: true

module Wallflower
  TaskType = Struct.new(:key, :title, :runner, :tries, :retry_wait, keyword_init: true)

  class MissingRunner < StandardError; end

  def self.register_task_type(key, title:, runner:, tries: 1, retry_wait: 60)
    task_types[key.to_sym] = TaskType.new(key: key.to_sym, title: title, runner: runner.to_s, tries: tries, retry_wait: retry_wait)
  end

  def self.task_type(key)
    task_types.fetch(key.to_sym)
  end

  def self.task_types
    @task_types ||= {}
  end

  def self.check_task_types!
    task_types.each_value do |task_type|
      next if task_type.runner.safe_constantize

      raise MissingRunner, "Wallflower task_type #{task_type.key} names the runner #{task_type.runner}, which does not exist."
    end
  end

  def self.reset_task_types!
    @task_types = {}
  end
end
