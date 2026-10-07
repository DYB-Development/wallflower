# frozen_string_literal: true

module Wallflower
  class Task < ApplicationRecord
    self.table_name = "wallflower_tasks"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    has_one_attached :result_file

    after_update_commit do
      broadcast_replace_to self, target: ActionView::RecordIdentifier.dom_id(self, :live), partial: "wallflower/tasks/live", locals: { task: self }
    end

    def kind_title
      Wallflower.kind(kind).title
    end

    def attach_result(io:, filename:)
      result_file.attach(io: io, filename: filename)
    end

    def set_total(total)
      update!(total: total)
    end

    def advance(by = 1)
      increment(:done, by).save!
    end
  end
end
