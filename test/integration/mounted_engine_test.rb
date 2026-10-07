# frozen_string_literal: true

require "test_helper"

class MountedEngineTest < ActionDispatch::IntegrationTest
  test "serves its pages under the path the host mounts it at" do
    get "/background"

    assert_select "h1", text: "Tasks"
  end
end
