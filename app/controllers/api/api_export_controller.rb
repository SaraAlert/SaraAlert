# frozen_string_literal: true

# API::ApiExportController: for exporting subjects via the API
class Api::ApiExportController < ApplicationApiController
  before_action do
    raise ClientError if
    doorkeeper_authorize!(
      :'system/Patient.read',
      :'system/Patient.*'
    ) ||
    doorkeeper_authorize!(
      :'system/QuestionnaireResponse.read'
    )

    set_client_app
  end

  before_action only: %i[nbs_patients] do
    status_not_acceptable && (raise ClientError) unless request.headers['Accept']&.include?('application/zip')
  end

  rescue_from ClientError, with: proc {}

  def set_client_app
    @current_client_app = OauthApplication.find_by(id: doorkeeper_token&.application_id)
    status_unauthorized && (raise ClientError) if @current_client_app.nil?
  end

  # Multi patient PHDC export
  def nbs_patients
    search_params = params.slice('workflow', 'monitoring', 'caseStatus', 'updatedSince')
    patients = search_params.blank? ? Patient.none : @current_client_app.jurisdiction&.all_patients_excluding_purged

    search_params.compact.transform_values { |v| v.to_s.downcase.strip }.each do |field, search|
      case field
      when 'workflow'
        patients = case search
                   when 'isolation'
                     patients.where(isolation: true)
                   when 'exposure'
                     patients.where(isolation: false)
                   else
                     Patient.none
                   end
      when 'monitoring'
        patients = case search
                   when 'true'
                     patients.where(monitoring: true)
                   when 'false'
                     patients.where(monitoring: false)
                   else
                     Patient.none
                   end
      when 'caseStatus'
        # Since case_status can be from a set of values, allow a list of comma separated values
        search = search.split(',').map(&:strip)
        patients = patients.where('lower(case_status) in (?)', search)
      when 'updatedSince'
        begin
          search = DateTime.parse(search)
          patients = patients.where(updated_at: search..)
        rescue ArgumentError
          patients = Patient.none
        end
      end
    end

    send_data PHDC::Serializer.new.patients_to_phdc_zip(patients, @current_client_app.jurisdiction).string, { type: 'application/zip' }
  end
end
