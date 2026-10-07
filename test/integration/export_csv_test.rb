# frozen_string_literal: true

require "test_helper"

class ExportCsvTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    load Rails.root.join("config/initializers/wallflower.rb")
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
  end

  test "a person starts the example CSV export and downloads its file once it finishes" do
    task = Wallflower.start(kind: :export_csv, person: person, params: { "rows" => [ [ "2026-10", 42 ], [ "2026-11", 7 ] ] })
    perform_enqueued_jobs

    get "/background/tasks/#{task.id}/download"

    assert_equal "month,total\n2026-10,42\n2026-11,7\n", response.body
  end
end
