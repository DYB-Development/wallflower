# frozen_string_literal: true

require "test_helper"

class Wallflower::ConfigurationTest < ActiveSupport::TestCase
  def teardown
    Wallflower.reset_configuration!
  end

  test "finds the current person through current_user unless the host names another method" do
    assert_equal :current_user, Wallflower.configuration.current_person_method
  end
end
