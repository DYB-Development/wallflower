Wallflower::Engine.routes.draw do
  root "tasks#index"
  resources :tasks, only: :show
end
