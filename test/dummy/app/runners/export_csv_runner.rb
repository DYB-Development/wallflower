# frozen_string_literal: true

require "csv"

class ExportCsvRunner
  def call(task)
    rows = task.params.fetch("rows")
    task.set_total(rows.size)
    csv = CSV.generate do |lines|
      lines << %w[month total]
      rows.each { |row| lines << row; task.advance }
    end
    task.attach_result(io: StringIO.new(csv), filename: "export.csv")
  end
end
