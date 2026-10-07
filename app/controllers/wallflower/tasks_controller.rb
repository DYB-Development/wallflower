# frozen_string_literal: true

module Wallflower
  class TasksController < ApplicationController
    def index
    end

    def show
      @task = Task.find_by(id: params[:id], person: current_person)
      head :not_found unless @task
    end
  end
end
