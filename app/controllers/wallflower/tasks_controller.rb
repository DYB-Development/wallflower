# frozen_string_literal: true

module Wallflower
  class TasksController < ApplicationController
    def index
    end

    def show
      @task = visible_tasks.find_by(id: params[:id])
      head :not_found unless @task
    end

    def download
      task = visible_tasks.find_by(id: params[:id])
      return head :not_found unless task&.result_file&.attached?

      send_data task.result_file.download, filename: task.result_file.filename.to_s, type: task.result_file.content_type
    end

    private

    def visible_tasks
      tasks = Task.where(person: wallflower_person)
      Wallflower.configuration.current_account_method ? tasks.where(account: wallflower_account) : tasks
    end
  end
end
