# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringDownloadsVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
    
  DOWNLOAD_TIMEOUT = 60
  DOWNLOAD_CHECK_INTERVAL = 0.1
  
  LINE_LIST_HEADERS = ['Monitoree', 'Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth',
  'End of Monitoring', 'Risk Level', 'Monitoring Plan', 'Latest Report', 'Transferred At',
  'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At',
  'Transferred From', 'Transferred To', 'Expected Purge Date']

  SARA_ALERT_FORMAT_HEADERS = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
  'American Indian or Alaska Native', 'Asian', 'Native Hawaiian or Other Pacific Islander', 'Ethnicity', 'Primary Language',
  'Secondary Language', 'Interpretation Required?', 'Nationality', 'Identifier (STATE/LOCAL)', 'Identifier (CDC)', 'Identifier (NNDSS)',
  'Address Line 1', 'Address City', 'Address State', 'Address Line 2', 'Address Zip', 'Address County', 'Foreign Address Line 1',
  'Foreign Address City', 'Foreign Address Country', 'Foreign Address Line 2', 'Foreign Address Zip', 'Foreign Address Line 3',
  'Foreign Address State', 'Monitored Address Line 1', 'Monitored Address City', 'Monitored Address State', 'Monitored Address Line 2',
  'Monitored Address Zip', 'Monitored Address County', 'Foreign Monitored Address Line 1', 'Foreign Monitored Address City',
  'Foreign Monitored Address State', 'Foreign Monitored Address Line 2', 'Foreign Monitored Address Zip', 'Foreign Monitored Address County',
  'Preferred Contact Method', 'Primary Telephone', 'Primary Telephone Type', 'Secondary Telephone', 'Secondary Telephone Type',
  'Preferred Contact Time', 'Email', 'Port of Origin', 'Date of Departure', 'Source of Report', 'Flight or Vessel Number',
  'Flight or Vessel Carrier', 'Port of Entry Into USA', 'Date of Arrival', 'Travel Related Notes', 'Additional Planned Travel Type',
  'Additional Planned Travel Destination', 'Additional Planned Travel Destination State', 'Additional Planned Travel Destination Country',
  'Additional Planned Travel Port of Departure', 'Additional Planned Travel Start Date', 'Additional Planned Travel End Date',
  'Additional Planned Travel Related Notes', 'Last Date of Exposure', 'Potential Exposure Location', 'Potential Exposure Country',
  'Contact of Known Case?', 'Contact of Known Case ID', 'Travel from Affected Country or Area?', 'Was in Health Care Facility With Known Cases?',
  'Health Care Facility with Known Cases Name', 'Laboratory Personnel?', 'Laboratory Personnel Facility Name', 'Health Care Personnel?',
  'Health Care Personnel Facility Name', 'Crew on Passenger or Cargo Flight?', 'Member of a Common Exposure Cohort?',
  'Common Exposure Cohort Name', 'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status']

  EXCEL_EXPORT_HEADERS = ['Patient ID'].concat(SARA_ALERT_FORMAT_HEADERS)

  BOOL_FIELDS = [:white, :black_or_african_american, :american_indian_or_alaska_native, :asian, :native_hawaiian_or_other_pacific_islander,
  :interpretation_required, :travel_to_affected_country_or_area, :was_in_health_care_facility_with_known_cases, :laboratory_personnel,
  :healthcare_personnel, :crew_on_passenger_or_cargo_flight, :member_of_a_common_exposure_cohort]
  
  def verify_line_list_csv(jurisdiction_id, isolation, tab)
    patients = Jurisdiction.find(jurisdiction_id).all_patients
    csv = get_csv("Sara-Alert-Line-List-#{tab}-????-??-??T??_??_??-??_??.csv")
    verify_csv_export(patients, csv, :line_list, LINE_LIST_HEADERS)
  end
  
  def verify_sara_alert_format_csv(jurisdiction_id, isolation, tab)
    patients = Jurisdiction.find(jurisdiction_id).all_patients
    csv = get_csv("Sara-Alert-Format-#{tab}-????-??-??T??_??_??-??_??.csv")
    verify_csv_export(patients, csv, :sara_alert_format, SARA_ALERT_FORMAT_HEADERS)
  end

  def verify_excel_purge_eligible_monitorees(jurisdiction_id)
    patients = Jurisdiction.find(jurisdiction_id).all_patients.purge_eligible
    xlsx = get_xlsx('Sara-Alert-Full-History-Purgeable-Monitorees-????-??-??T??_??_??-??_??.xlsx')
    verify_excel_export(patients, xlsx)
  end

  def verify_excel_all_monitorees(jurisdiction_id)
    patients = Jurisdiction.find(jurisdiction_id).all_patients
    xlsx = get_xlsx('Sara-Alert-Full-History-All-Monitorees-????-??-??T??_??_??-??_??.xlsx')
    verify_excel_export(patients, xlsx)
  end

  def verify_csv_export(patients, csv, type, headers)
    assert patients.size == csv.length()
    headers.each_with_index { |header, col|
      assert_equal(header, csv.headers[col], "For header: #{header}")
    }
    patients.each_with_index { |patient, row|
      details = type == :line_list ? patient.linelist : patient.comprehensive_details
      details.keys.each_with_index { |field, col|
        if field == :name
          assert_equal(details[field][:name], csv[row][col], "For field: #{field}")
        elsif BOOL_FIELDS.include?(field)
          assert_equal(details[field] ? 'true' : 'false', csv[row][col], "For field: #{field}")
        else
          assert_equal(details[field], csv[row][col], "For field: #{field}")
        end
      }
    }
  end

  def verify_excel_export(patients, xlsx)
    
  end

  def get_csv(file_name_glob)
    CSV.parse(File.read(get_file_name(file_name_glob)), :headers => true)
  end

  def get_xlsx(file_name_glob)
    Roo::Spreadsheet.open(get_file_name(file_name_glob))
  end

  def get_file_name(file_name_glob)
    Timeout.timeout(DOWNLOAD_TIMEOUT) do
      sleep(DOWNLOAD_CHECK_INTERVAL) until Dir.glob(File.join(@@system_test_utils.get_download_path, file_name_glob)).any?
    end
    Dir.glob(File.join(@@system_test_utils.get_download_path, file_name_glob))[0]
  end
end 
