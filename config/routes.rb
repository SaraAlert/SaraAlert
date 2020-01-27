Rails.application.routes.draw do
  devise_for :users

  root to: "home#index"

  resources :patients, only: [:index, :new, :create, :show]
end
