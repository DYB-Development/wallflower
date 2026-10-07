# frozen_string_literal: true

module Wallflower
  class ApplicationController < ::ApplicationController
    before_action { send(Wallflower.configuration.authentication_method) }
  end
end
