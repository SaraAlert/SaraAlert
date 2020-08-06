Rails.application.routes.draw do
  use_doorkeeper

  if ADMIN_OPTIONS['report_mode']
    root to: 'assessments#landing'
  else
    root to: 'home#index'
  end

  devise_for :users, only: [:sessions, :authy], controllers: {devise_authy: 'devise_authy'}, :path_names => {
    verify_authy: "/verify-token",
    enable_authy: "/enable-two-factor",
    verify_authy_installation: "/verify-installation"
  }

  as :user do
    get 'users/edit', to: 'users/registrations#edit', as: :edit_user_registration
    put 'users', to: 'users/registrations#update', as: :user_registration
    get 'users/password_expired', to: 'users/registrations#password_expired', as: :user_password_expired
  end

  namespace :fhir, defaults: { format: :json } do
    namespace :r4 do
      get '/metadata', to: 'api#capability_statement'
      get '/.well-known/smart-configuration', to: 'api#well_known'
      get '/:resource_type/:id', to: 'api#show'
      put '/:resource_type/:id', to: 'api#update'
      post '/:resource_type', to: 'api#create'
      get '/:resource_type', to: 'api#search'
      post '/:resource_type/_search', to: 'api#search'
      get '/Patient/:id/$everything', to: 'api#all'
    end
  end
  get '/.well-known/smart-configuration', to: 'fhir/r4/api#well_known'
  get '/redirect', to: redirect { |params, request| "/oauth/authorize/native?#{request.params.to_query}" }

  resources :patients, only: [:index, :new, :create, :show, :edit, :update]

  resources :admin, only: [:index]
  get 'admin/users', to: 'admin#users'
  
  post 'admin/create_user', to: 'admin#create_user'
  post 'admin/edit_user', to: 'admin#edit_user'
  post 'admin/reset_password', to: 'admin#reset_password'
  post 'admin/reset_2fa', to: 'admin#reset_2fa'
  post 'admin/email', to: 'admin#email'
  post 'admin/email_all', to: 'admin#email_all'


  resources :histories, only: [:create]

  post '/laboratories', to: 'laboratories#create'
  post '/laboratories/:id', to: 'laboratories#update'

  get '/jurisdictions/paths', to: 'jurisdictions#jurisdiction_paths', as: :jurisdiction_paths
  get '/jurisdictions/assigned_users', to: 'jurisdictions#assigned_users_for_viewable_patients', as: :assigned_users_for_viewable_patients

  post '/close_contacts', to: 'close_contacts#create'
  post '/close_contacts/:id', to: 'close_contacts#update'

  get '/patients/:id/group', to: 'patients#new_group_member'

  get '/export/csv/patients/:type/:workflow', to: 'export#csv'
  get '/export/excel/patients/comprehensive/:workflow', to: 'export#excel_comprehensive_patients'
  get '/export/excel/patients/full_history/:scope', to: 'export#excel_full_history_patients'
  get '/export/excel/patients/full_history/patient/:patient_id', to: 'export#excel_full_history_patient'
  get '/export/download/:lookup', to: 'downloads#download', as: :export_download

  post '/import/:workflow/:format', to: 'import#import'
  get '/import/download_guidance', to: 'import#download_guidance'

  get '/patients/:id/household_removeable', to: 'patients#household_removeable'
  post '/patients/bulk_edit/status', to: 'patients#bulk_update_status'
  post '/patients/:id/status', to: 'patients#update_status'
  post '/patients/:id/status/clear', to: 'patients#clear_assessments'
  post '/patients/:id/status/clear/:assessment_id', to: 'patients#clear_assessment'
  post '/patients/:id/reminder', to: 'patients#send_reminder'
  post '/patients/:id/update_hoh', to: 'patients#update_hoh'

  resources :patients, param: :submission_token do
    resources :assessments, only: [:create, :new, :index]
  end

  post '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report
  post '/twilio', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report_twilio
  post '/report/twilio', to: 'assessments#create', as: :create_patient_assessment_jurisdiction_report_twilio_report

  get '/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction
  get '/patients/:patient_submission_token/:lang/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction_lang
  get '/report/patients/:patient_submission_token/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction_report
  get '/report/patients/:patient_submission_token/:lang/:unique_identifier', to: 'assessments#new', as: :new_patient_assessment_jurisdiction_report_lang
  get '/already_reported', to: 'assessments#already_reported', as: :already_reported
  get '/report/already_reported', to: 'assessments#already_reported', as: :already_reported_report

  post '/patients/:patient_submission_token/assessments/:id', to: 'assessments#update'

  get '/public_health', to: 'public_health#exposure', as: :public_health
  get '/public_health/isolation', to: 'public_health#isolation', as: :public_health_isolation
  get '/public_health/patients', to: 'public_health#patients', as: :public_health_patients
  get '/public_health/patients/counts/workflow', to: 'public_health#workflow_counts', as: :workflow_counts
  get '/public_health/patients/counts/:workflow/:tab', to: 'public_health#tab_counts', as: :tab_counts
  get '/public_health/patients/self_reporting', to: 'public_health#self_reporting', as: :self_reporting

  get '/analytics', to: 'analytics#index', as: :analytics
  get '/county_level_maps/:mapFile', to: 'analytics#clm_geo_json'

  # Errors
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal_server_error'
end
