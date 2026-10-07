# frozen_string_literal: true

module Wallflower
  class TasksController < ApplicationController
    def index
    end

    def show
      @task = Task.find(params[:id])
    end
  end
end
