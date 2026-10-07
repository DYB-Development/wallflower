# frozen_string_literal: true

module Wallflower
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
