# frozen_string_literal: true

require "test_helper"

class MountedEngineTest < ActionDispatch::IntegrationTest
  def setup
    ApplicationController.signed_in_user = User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
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
end
