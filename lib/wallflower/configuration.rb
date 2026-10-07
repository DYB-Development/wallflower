# frozen_string_literal: true

module Wallflower
  class Configuration
    attr_accessor :authentication_method

    def initialize
      @authentication_method = :authenticate_user!
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
