# frozen_string_literal: true

module Wallflower
  class Task < ApplicationRecord
    self.table_name = "wallflower_tasks"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    has_one_attached :result_file
    has_many :refusals, dependent: :destroy

    after_update_commit do
      broadcast_replace_to self, target: ActionView::RecordIdentifier.dom_id(self, :live), partial: "wallflower/tasks/live", locals: { task: self }
    end

    STATUS_VARIANTS = { "finished" => :success, "failed" => :danger, "running" => :info }.freeze

    def status_variant
      STATUS_VARIANTS.fetch(status, :neutral)
    end

    def kind_title
      Wallflower.kind(kind).title
    end

    def attach_result(io:, filename:)
      result_file.attach(io: io, filename: filename)
    end

    def changed_count
      done - refusals.size
    end

    def link_result(url)
      update!(result_url: url)
    end

    def refuse(label:, reason:)
      refusals.create!(label: label, reason: reason)
    end

    def set_total(total)
      update!(total: total)
    end

    def advance(by = 1)
      increment(:done, by).save!
    end
  end
end
