# frozen_string_literal: true

module Wallflower
  class Refusal < ApplicationRecord
    self.table_name = "wallflower_refusals"

    belongs_to :task
  end
end
