# frozen_string_literal: true

# ApiExportController: for exporting subjects via the API
class ApiExportController < ActionController::API
  before_action do
    doorkeeper_authorize!(
      :'system/Patient.read',
      :'system/Patient.*'
    )
  end
  before_action :set_client_app

  def set_client_app
    @current_client_app = OauthApplication.find_by(id: doorkeeper_token&.application_id)
    head :unauthorized if @current_client_app.nil?
  end

  # Multi patient PHDC export
  def nbs_patients
    head(:not_acceptable) && return unless request.headers['Accept']&.include?('application/zip')

    search_params = params.slice('workflow', 'monitoring', 'caseStatus', 'updatedAt')
    query = search_params.blank? ? Patient.none : Jurisdiction.find_by(id: @current_client_app[:jurisdiction_id])&.all_patients_excluding_purged
    search_params.each do |field, search|
      next unless search.present?

      search = search.downcase.strip

      case field
      when 'workflow'
        query = case search
                when 'isolation'
                  query.where(isolation: true)
                when 'exposure'
                  query.where(isolation: false)
                else
                  Patient.none
                end
      when 'monitoring'
        query = case search
                when 'true'
                  query.where(monitoring: true)
                when 'false'
                  query.where(monitoring: false)
                else
                  Patient.none
                end
      when 'caseStatus'
        # Since case_status can be from a set of values, allow a list of comma separated values
        search = search.split(',').map(&:strip)
        query = query.where('lower(case_status) in (?)', search)
      when 'updatedAt'
        begin
          search = DateTime.parse(search)
          query = query.where(updated_at: search..)
        rescue ArgumentError
          query = Patient.none
        end
      end
    end

    send_data PHDC::Serializer.new.patients_to_phdc_zip(query, @current_client_app.jurisdiction).string, { type: 'application/zip' }
  end
end
