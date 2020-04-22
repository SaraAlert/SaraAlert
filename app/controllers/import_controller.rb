# frozen_string_literal: true

require 'roo'

# ImportController: for importing subjects from other formats
class ImportController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.can_import?
  end

  def error
    @error_msg = 'Monitoree import file appears to be invalid.'
  end

  def epix
    redirect_to(root_url) && return unless current_user.can_import?

    # Load and parse Epi-X file
    begin
      xlxs = Roo::Excelx.new(params[:epix].tempfile.path, file_warning: :ignore)
      @patients = []
      xlxs.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        sex = 'Male' if row[13] == 'M'
        sex = 'Female' if row[13] == 'F'
        @patients << {
          user_defined_id_statelocal: row[0],
          flight_or_vessel_number: row[1],
          user_defined_id_cdc: row[4],
          primary_language: row[7],
          date_of_arrival: row[8],
          port_of_entry_into_usa: row[9],
          last_name: row[10],
          first_name: row[11],
          date_of_birth: row[12],
          sex: sex,
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
          was_in_health_care_facility_with_known_cases: !row[42].blank?,
          appears_to_be_duplicate: current_user.viewable_patients.matches(row[11], row[10], sex, row[12]).exists?,
          isolation: params.permit(:workflow)[:workflow] == 'isolation'
        }
      end
    rescue StandardError
      redirect_to(controller: 'import', action: 'error') && (return)
    end
  end

  def download_guidance
    send_file(
      "#{Rails.root}/public/sara_alert_comprehensive_monitoree.xlsx",
      filename: 'sara_alert_comprehensive_monitoree.xlsx',
      type: 'application/vnd.ms-excel'
    )
  end

  def comprehensive_monitorees
    redirect_to(root_url) && return unless current_user.can_import?

    # Load and parse patient import excel
    begin
      xlxs = Roo::Excelx.new(params[:comprehensive_monitorees].tempfile.path, file_warning: :ignore)
      @patients = []
      xlxs.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        @patients << {
          first_name: row[0],
          middle_name: row[1],
          last_name: row[2],
          date_of_birth: row[3],
          sex: row[4],
          white: row[5],
          black_or_african_american: row[6],
          american_indian_or_alaska_native: row[7],
          asian: row[8],
          native_hawaiian_or_other_pacific_islander: row[9],
          ethnicity: row[10],
          primary_language: row[11],
          secondary_language: row[12],
          interpretation_required: row[13],
          nationality: row[14],
          user_defined_id_statelocal: row[15],
          user_defined_id_cdc: row[16],
          user_defined_id_nndss: row[17],
          address_line_1: row[18],
          address_city: row[19],
          address_state: row[20],
          address_line_2: row[21],
          address_zip: row[22],
          address_county: row[23],
          foreign_address_line_1: row[24],
          foreign_address_city: row[25],
          foreign_address_country: row[26],
          foreign_address_line_2: row[27],
          foreign_address_zip: row[28],
          foreign_address_line_3: row[29],
          foreign_address_state: row[30],
          monitored_address_line_1: row[31],
          monitored_address_city: row[32],
          monitored_address_state: row[33],
          monitored_address_line_2: row[34],
          monitored_address_zip: row[35],
          monitored_address_county: row[36],
          foreign_monitored_address_line_1: row[37],
          foreign_monitored_address_city: row[38],
          foreign_monitored_address_state: row[39],
          foreign_monitored_address_line_2: row[40],
          foreign_monitored_address_zip: row[41],
          foreign_monitored_address_county: row[42],
          preferred_contact_method: row[43],
          primary_telephone: row[44],
          primary_telephone_type: row[45],
          secondary_telephone: row[46],
          secondary_telephone_type: row[47],
          preferred_contact_time: row[48],
          email: row[49],
          port_of_origin: row[50],
          date_of_departure: row[51],
          source_of_report: row[52],
          flight_or_vessel_number: row[53],
          flight_or_vessel_carrier: row[54],
          port_of_entry_into_usa: row[55],
          date_of_arrival: row[56],
          travel_related_notes: row[57],
          additional_planned_travel_type: row[58],
          additional_planned_travel_destination: row[59],
          additional_planned_travel_destination_state: row[60],
          additional_planned_travel_destination_country: row[61],
          additional_planned_travel_port_of_departure: row[62],
          additional_planned_travel_start_date: row[63],
          additional_planned_travel_end_date: row[64],
          additional_planned_travel_related_notes: row[65],
          last_date_of_exposure: row[66],
          potential_exposure_location: row[67],
          potential_exposure_country: row[68],
          contact_of_known_case: row[69],
          contact_of_known_case_id: row[70],
          travel_to_affected_country_or_area: row[71],
          was_in_health_care_facility_with_known_cases: row[72],
          was_in_health_care_facility_with_known_cases_facility_name: row[73],
          laboratory_personnel: row[74],
          laboratory_personnel_facility_name: row[75],
          healthcare_personnel: row[76],
          healthcare_personnel_facility_name: row[77],
          crew_on_passenger_or_cargo_flight: row[78],
          member_of_a_common_exposure_cohort: row[79],
          member_of_a_common_exposure_cohort_type: row[80],
          exposure_risk_assessment: row[81],
          monitoring_plan: row[82],
          exposure_notes: row[83],
          appears_to_be_duplicate: current_user.viewable_patients.matches(row[0], row[2], row[4], row[3]).exists?,
          isolation: params.permit(:workflow)[:workflow] == 'isolation'
        }
      end
    rescue StandardError
      redirect_to(controller: 'import', action: 'error') && (return)
    end
  end
end
