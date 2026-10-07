# frozen_string_literal: true

module Wallflower
  class Task < ApplicationRecord
    self.table_name = "wallflower_tasks"

    belongs_to :person, polymorphic: true
    belongs_to :account, polymorphic: true, optional: true

    def kind_title
      Wallflower.kind(kind).title
    end

    def set_total(total)
      update!(total: total)
    end

    def advance(by = 1)
      increment!(:done, by)
    end
  end
end
