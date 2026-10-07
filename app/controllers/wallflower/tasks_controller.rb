# frozen_string_literal: true

module Wallflower
  class TasksController < ApplicationController
    def index
    end

    def show
      @task = visible_tasks.find_by(id: params[:id])
      head :not_found unless @task
    end

    private

    def visible_tasks
      tasks = Task.where(person: wallflower_person)
      Wallflower.configuration.current_account_method ? tasks.where(account: wallflower_account) : tasks
    end
  end
end
