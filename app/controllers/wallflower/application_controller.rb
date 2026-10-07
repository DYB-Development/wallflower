# frozen_string_literal: true

module Wallflower
  class ApplicationController < ::ApplicationController
    before_action { send(Wallflower.configuration.authentication_method) }

    layout -> { Wallflower.configuration.layout }

    helper KeystoneUiHelper

    private

    def wallflower_person
      send(Wallflower.configuration.current_person_method)
    end

    def wallflower_account
      send(Wallflower.configuration.current_account_method)
    end
  end
end
