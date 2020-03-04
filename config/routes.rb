Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users, only: [:sessions]
  as :user do
    get 'users/edit' => 'users/registrations#edit', :as => 'edit_user_registration'
    put 'users' => 'users/registrations#update', :as => 'user_registration'
  end

  resources :patients, only: [:index, :new, :create, :show, :edit, :update, :new_group_member]

  resources :admin, only: [:index, :create_user]

  post 'admin/create_user', to: 'admin#create_user'

  resources :histories, only: [:create]

  get '/patients/:id/group', to: 'patients#new_group_member'

  post '/patients/:id/status', to: 'patients#update_status'

  post '/patients/:id/status/clear', to: 'patients#clear_assessments'

  resources :patients, param: :submission_token do
    resources :assessments, only: [:create, :new, :index]
  end

  post '/patients/:patient_submission_token/assessments/:id', to: 'assessments#update'

  get '/public_health', to: 'public_health#index', as: :public_health

  get '/analytics', to: 'analytics#index', as: :analytics
end
