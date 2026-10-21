# frozen_string_literal: true

Rails.application.routes.draw do
  mount Wallflower::Engine => "/background"

  get "home", to: redirect("/"), as: :home
  get "host/tasks/:id/download", to: redirect("/"), as: :download_task
end
