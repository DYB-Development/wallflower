# frozen_string_literal: true

Wallflower.register_task_type :export_csv, title: "Export to CSV", runner: "ExportCsvRunner"

Wallflower.configure do |config|
  config.on_finish = ->(task) { Notification.create!(user: task.person, message: "#{task.task_type_title} finished") }
end
