# frozen_string_literal: true

require "test_helper"

class Wallflower::ResultFileTest < ActiveSupport::TestCase
  test "a runner attaches a file to its task as the result" do
    task = Wallflower::Task.create!(kind: "export", person: User.create!(name: "Rep"))

    task.attach_result(io: StringIO.new("month,total\n2026-10,42\n"), filename: "transactions.csv")

    assert_equal "month,total\n2026-10,42\n", task.reload.result_file.download
  end
end
