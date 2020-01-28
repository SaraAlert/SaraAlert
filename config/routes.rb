Rails.application.routes.draw do
  devise_for :users

  root to: "home#index"

  resources :patients, only: [:index, :new, :create, :show]

  get '/monitor_dashboard', to: 'monitor_dashboard#index'
end
