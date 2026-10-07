# frozen_string_literal: true

require "test_helper"

class Wallflower::RefusalTest < ActiveSupport::TestCase
  test "a runner records a refused row with a label for the row and a reason" do
    task = Wallflower::Task.create!(kind: "import", person: User.create!(name: "Rep"))

    task.refuse(label: "Row 4", reason: "Amount is missing")

    assert_equal [ [ "Row 4", "Amount is missing" ] ], task.refusals.map { |refusal| [ refusal.label, refusal.reason ] }
  end
end
