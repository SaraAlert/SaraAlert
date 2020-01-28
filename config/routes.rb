Rails.application.routes.draw do
  devise_for :users

  root to: "home#index"

  resources :patients, only: [:index, :new, :create, :show]

  resources :patients do
    resources :assessments, only: [:create, :new, :index]
  end

  get '/monitor_dashboard', to: 'monitor_dashboard#index', as: :monitor_dashboard

end
