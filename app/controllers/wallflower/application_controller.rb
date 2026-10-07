# frozen_string_literal: true

module Wallflower
  class ApplicationController < ::ApplicationController
    before_action { send(Wallflower.configuration.authentication_method) }

    layout -> { Wallflower.configuration.layout }

    helper KeystoneUiHelper

    private

    def current_person
      send(Wallflower.configuration.current_person_method)
    end
  end
end
