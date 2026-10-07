# frozen_string_literal: true

require "test_helper"

class Wallflower::StartTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  test "starting a task returns it queued" do
    task = Wallflower.start(kind: :export, person: person, params: { "month" => "2026-10" })

    assert_equal "queued", task.status
  end
end
