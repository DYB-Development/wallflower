# frozen_string_literal: true

require "test_helper"

class Wallflower::ResultLinkTest < ActiveSupport::TestCase
  test "a runner sets a link to a page in the host app as its task's result" do
    task = Wallflower::Task.create!(kind: "report", person: User.create!(name: "Rep"))

    task.link_result("/console/reports/42")

    assert_equal "/console/reports/42", task.reload.result_url
  end
end
