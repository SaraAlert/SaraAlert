# frozen_string_literal: true

require 'roo'

# ImportController: for importing subjects from other formats
class ImportController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.can_import?
  end

  def error
    @error_msg = 'Epi-X file appears to be invalid.'
  end

  def epix
    redirect_to(root_url) && return unless current_user.can_import?

    # Load and parse Epi-X file
    begin
      xlxs = Roo::Excelx.new(params[:epix].tempfile.path, file_warning: :ignore)

      @patients = []

      xlxs.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        epix_fields = {
          user_defined_id_statelocal: row[0],
          flight_or_vessel_number: row[1],
          user_defined_id_cdc: row[4],
          primary_language: row[7],
          date_of_arrival: row[8],
          port_of_entry_into_usa: row[9],
          last_name: row[10],
          first_name: row[11],
          date_of_birth: row[12],
          sex: row[13],
          address_line_1: row[16],
          address_city: row[17],
          address_state: row[18],
          address_zip: row[19],
          monitored_address_line_1: row[20],
          monitored_address_city: row[21],
          monitored_address_state: row[22],
          monitored_address_zip: row[23],
          primary_telephone: row[28],
          secondary_telephone: row[29],
          email: row[30],
          potential_exposure_location: row[35],
          potential_exposure_country: row[35],
          date_of_departure: row[36],
          contact_of_known_case: !row[41].blank?,
          was_in_health_care_facility_with_known_cases: !row[42].blank?
        }
        @patients << epix_fields
      end
    rescue StandardError
      redirect_to(controller: 'import', action: 'error') && (return)
    end
  end
end
