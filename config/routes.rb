Wallflower::Engine.routes.draw do
  root "tasks#index"
  resources :tasks, only: :show do
    get :download, on: :member
  end
end
