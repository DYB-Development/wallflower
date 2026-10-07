# frozen_string_literal: true

require "test_helper"

class MountedEngineTest < ActionDispatch::IntegrationTest
  def setup
    ApplicationController.signed_in_user = User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    Wallflower.reset_configuration!
  end

  test "serves its pages under the path the host mounts it at" do
    get "/background"

    assert_select "h1", text: "Tasks"
  end

  test "hands a signed-out visitor to the host's sign-in check" do
    ApplicationController.signed_in_user = nil

    get "/background"

    assert_response :unauthorized
  end

  test "checks sign-in with the method the host names" do
    ApplicationController.define_method(:refuse_everyone) { head :forbidden }
    Wallflower.configure { |config| config.authentication_method = :refuse_everyone }

    get "/background"

    assert_response :forbidden
  ensure
    ApplicationController.remove_method(:refuse_everyone)
  end

  test "draws its pages in the layout the host names" do
    Wallflower.configure { |config| config.layout = "back_office" }

    get "/background"

    assert_select "#back-office"
  end
end
