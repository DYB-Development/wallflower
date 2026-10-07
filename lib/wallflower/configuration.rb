# frozen_string_literal: true

module Wallflower
  class Configuration
    attr_accessor :authentication_method, :layout, :current_person_method, :current_account_method, :on_finish

    def initialize
      @authentication_method = :authenticate_user!
      @layout = "application"
      @current_person_method = :current_user
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
