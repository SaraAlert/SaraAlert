Rails.application.routes.draw do
  if ADMIN_OPTIONS['report_mode']
    root to: 'assessments#landing'
  else
    root to: 'home#index'
  end

  devise_for :users, only: [:sessions, :authy], :path_names => {
    verify_authy: "/verify-token",
    enable_authy: "/enable-two-factor",
    verify_authy_installation: "/verify-installation",
    authy_onetouch_status: "/onetouch-status"
  }

  as :user do
    get 'users/edit', to: 'users/registrations#edit', as: :edit_user_registration
    put 'users', to: 'users/registrations#update', as: :user_registration
    get 'users/password_expired', to: 'users/registrations#password_expired', as: :user_password_expired
  end

  resources :patients, only: [:index, :new, :create, :show, :edit, :update, :new_group_member]

  resources :admin, only: [:index, :create_user]

  post 'admin/create_user', to: 'admin#create_user'
  post 'admin/edit_user', to: 'admin#edit_user'
  post 'admin/lock_user', to: 'admin#lock_user'
  post 'admin/unlock_user', to: 'admin#unlock_user'
  post 'admin/reset_password', to: 'admin#reset_password'
  post 'admin/reset_2fa', to: 'admin#reset_2fa'

  resources :histories, only: [:create]

  get '/patients/:id/group', to: 'patients#new_group_member'

  get '/export/:type/csv', to: 'export#csv'
  get '/export/:type/csv_comprehensive', to: 'export#csv_comprehensive'
  get '/export/isolation/:type/csv', to: 'export#csv_isolation'
  get '/export/isolation/:type/csv_comprehensive', to: 'export#csv_comprehensive_isolation'

  post '/import/:workflow/epix', to: 'import#epix'
  post '/import/:workflow/comprehensive_monitorees', to: 'import#comprehensive_monitorees'
  get '/import/download_guidance', to: 'import#download_guidance'
  get '/import/error', to: 'import#error'

  post '/patients/:id/status', to: 'patients#update_status'
  post '/patients/:id/status/clear', to: 'patients#clear_assessments'
  post '/patients/:id/reminder', to: 'patients#send_reminder'

  resources :patients, param: :submission_token do
    resources :assessments, only: [:create, :new, :index]
  end

  post '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report
  post '/twilio', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report_twilio
  post '/report/twilio', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report_twilio_report

  get '/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction
  get '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction_report
  get '/already_reported', to: 'assessments#already_reported', as: :already_reported
  get '/report/already_reported', to: 'assessments#already_reported', as: :already_reported_report

  post '/patients/:patient_submission_token/assessments/:id', to: 'assessments#update'

  get '/public_health/all_patients', to: 'public_health#all_patients_exposure', as: :public_health_all_patients_exposure
  get '/public_health/asymptomatic_patients', to: 'public_health#asymptomatic_patients_exposure', as: :public_health_asymptomatic_patients_exposure
  get '/public_health/pui_patients', to: 'public_health#pui_patients_exposure', as: :public_health_pui_patients_exposure
  get '/public_health/non_reporting_patients', to: 'public_health#non_reporting_patients_exposure', as: :public_health_non_reporting_patients_exposure
  get '/public_health/symptomatic_patients', to: 'public_health#symptomatic_patients_exposure', as: :public_health_symptomatic_patients_exposure
  get '/public_health/closed_patients', to: 'public_health#closed_patients_exposure', as: :public_health_closed_patients_exposure
  get '/public_health/transferred_in_patients', to: 'public_health#transferred_in_patients_exposure', as: :public_health_transferred_in_patients_exposure
  get '/public_health/transferred_out_patients', to: 'public_health#transferred_out_patients_exposure', as: :public_health_transferred_out_patients_exposure
  get '/public_health', to: 'public_health#exposure', as: :public_health

  get '/public_health/isolation/all_patients', to: 'public_health#all_patients_isolation', as: :public_health_all_patients_isolation
  get '/public_health/isolation/requiring_review_patients', to: 'public_health#requiring_review_patients_isolation', as: :public_health_requiring_review_patients_isolation
  get '/public_health/isolation/non_reporting_patients', to: 'public_health#non_reporting_patients_isolation', as: :public_health_non_reporting_patients_isolation
  get '/public_health/isolation/reporting_patients', to: 'public_health#reporting_patients_isolation', as: :public_health_reporting_patients_isolation
  get '/public_health/isolation/closed_patients', to: 'public_health#closed_patients_isolation', as: :public_health_closed_patients_isolation
  get '/public_health/isolation/transferred_in_patients', to: 'public_health#transferred_in_patients_isolation', as: :public_health_transferred_in_patients_isolation
  get '/public_health/isolation/transferred_out_patients', to: 'public_health#transferred_out_patients_isolation', as: :public_health_transferred_out_patients_isolation
  get '/public_health/isolation', to: 'public_health#isolation', as: :public_health_isolation

  get '/analytics', to: 'analytics#index', as: :analytics
end
