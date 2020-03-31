Rails.application.routes.draw do
  if ADMIN_OPTIONS['report_mode']
    root to: 'assessments#landing'
  else
    root to: 'home#index'
  end

  devise_for :users, only: [:sessions]
  as :user do
    get 'users/edit', to: 'users/registrations#edit', as: :edit_user_registration
    put 'users', to: 'users/registrations#update', as: :user_registration
    get 'users/password_expired', to: 'users/registrations#password_expired', as: :user_password_expired
  end

  resources :patients, only: [:index, :new, :create, :show, :edit, :update, :new_group_member]

  resources :admin, only: [:index, :create_user]

  post 'admin/create_user', to: 'admin#create_user'

  resources :histories, only: [:create]

  get '/patients/:id/group', to: 'patients#new_group_member'

  get '/export/:type/csv', to: 'export#csv'

  post '/import/epix', to: 'import#epix'
  get '/import/error', to: 'import#error'

  post '/patients/:id/status', to: 'patients#update_status'
  post '/patients/:id/status/clear', to: 'patients#clear_assessments'
  post '/patients/:id/reminder', to: 'patients#send_reminder'

  resources :patients, param: :submission_token do
    resources :assessments, only: [:create, :new, :index]
  end

  post '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report

  get '/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction
  get '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction_report
  get '/already_reported', to: 'assessments#already_reported', as: :already_reported
  get '/report/already_reported', to: 'assessments#already_reported', as: :already_reported_report

  post '/patients/:patient_submission_token/assessments/:id', to: 'assessments#update'

  get '/public_health/asymptomatic_patients', to: 'public_health#asymptomatic_patients', as: :public_health_asymptomatic_patients
  get '/public_health/pui_patients', to: 'public_health#pui_patients', as: :public_health_pui_patients
  get '/public_health/non_reporting_patients', to: 'public_health#non_reporting_patients', as: :public_health_non_reporting_patients
  get '/public_health/symptomatic_patients', to: 'public_health#symptomatic_patients', as: :public_health_symptomatic_patients
  get '/public_health/closed_patients', to: 'public_health#closed_patients', as: :public_health_closed_patients
  get '/public_health/transferred_in_patients', to: 'public_health#transferred_in_patients', as: :public_health_transferred_in_patients
  get '/public_health/transferred_out_patients', to: 'public_health#transferred_out_patients', as: :public_health_transferred_out_patients
  get '/public_health', to: 'public_health#index', as: :public_health

  get '/analytics', to: 'analytics#index', as: :analytics
end
