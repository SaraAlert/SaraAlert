# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  before_action :authenticate_user!

  LINELIST_HEADERS = ['Monitoree', 'Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level', 'Monitoring Plan',
                      'Latest Report', 'Transferred At', 'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At', 'Transferred From',
                      'Transferred To', 'Expected Purge Date'].freeze

  COMPREHENSIVE_HEADERS = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
                           'American Indian or Alaska Native', 'Asian', 'Native Hawaiian or Other Pacific Islander', 'Ethnicity', 'Primary Language',
                           'Secondary Language', 'Interpretation Required?', 'Nationality', 'Identifier (STATE/LOCAL)', 'Identifier (CDC)',
                           'Identifier (NNDSS)', 'Address Line 1', 'Address City', 'Address State', 'Address Line 2', 'Address Zip', 'Address County',
                           'Foreign Address Line 1', 'Foreign Address City', 'Foreign Address Country', 'Foreign Address Line 2', 'Foreign Address Zip',
                           'Foreign Address Line 3', 'Foreign Address State', 'Monitored Address Line 1', 'Monitored Address City', 'Monitored Address State',
                           'Monitored Address Line 2', 'Monitored Address Zip', 'Monitored Address County', 'Foreign Monitored Address Line 1',
                           'Foreign Monitored Address City', 'Foreign Monitored Address State', 'Foreign Monitored Address Line 2',
                           'Foreign Monitored Address Zip', 'Foreign Monitored Address County', 'Preferred Contact Method', 'Primary Telephone',
                           'Primary Telephone Type', 'Secondary Telephone', 'Secondary Telephone Type', 'Preferred Contact Time', 'Email', 'Port of Origin',
                           'Date of Departure', 'Source of Report', 'Flight or Vessel Number', 'Flight or Vessel Carrier', 'Port of Entry Into USA',
                           'Date of Arrival', 'Travel Related Notes', 'Additional Planned Travel Type', 'Additional Planned Travel Destination',
                           'Additional Planned Travel Destination State', 'Additional Planned Travel Destination Country',
                           'Additional Planned Travel Port of Departure', 'Additional Planned Travel Start Date', 'Additional Planned Travel End Date',
                           'Additional Planned Travel Related Notes', 'Last Date of Exposure', 'Potential Exposure Location', 'Potential Exposure Country',
                           'Contact of Known Case?', 'Contact of Known Case ID', 'Travel from Affected Country or Area?',
                           'Was in Health Care Facility With Known Cases?', 'Health Care Facility with Known Cases Name', 'Laboratory Personnel?',
                           'Laboratory Personnel Facility Name', 'Health Care Personnel?', 'Health Care Personnel Facility Name',
                           'Crew on Passenger or Cargo Flight?', 'Member of a Common Exposure Cohort?', 'Common Exposure Cohort Name',
                           'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status', 'Symptom Onset Date', 'Case Status', 'Lab 1 Test Type',
                           'Lab 1 Specimen Collection Date', 'Lab 1 Report Date', 'Lab 1 Result', 'Lab 2 Test Type', 'Lab 2 Specimen Collection Date',
                           'Lab 2 Report Date', 'Lab 2 Result'].freeze

  MONITOREES_LIST_HEADERS = ['Patient ID'] + COMPREHENSIVE_HEADERS.freeze

  def csv
    # Verify permissions
    redirect_to(root_url) && return unless current_user.can_export?

    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    headers = params[:type] == 'linelist' ? LINELIST_HEADERS : COMPREHENSIVE_HEADERS

    # Grab patients to export based on monitoring type
    patients = current_user.viewable_patients.where(isolation: params[:workflow] == 'isolation')

    # Build CSV
    csv_result = CSV.generate(headers: true) do |csv|
      csv << headers
      patients.each do |patient|
        p = params[:type] == 'linelist' ? patient.linelist.values : patient.comprehensive_details.values
        p[0] = p[0][:name] if params[:type] == 'linelist'
        csv << p
      end
    end

    send_data csv_result, filename: "Sara-Alert-#{params[:workflow].capitalize}-#{params[:type].capitalize}-#{DateTime.now}.csv"
  end

  def excel_comprehensive_patients
    # Verify permissions
    redirect_to(root_url) && return unless current_user.can_export?

    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    # Grab patients to export
    patients = current_user.viewable_patients.where(isolation: params[:workflow] == 'isolation')

    # Build Excel
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees') do |sheet|
        headers = COMPREHENSIVE_HEADERS
        sheet.add_row headers
        patients.each do |patient|
          sheet.add_row patient.comprehensive_details.values, { types: Array.new(headers.length, :string) }
        end
      end
      send_data p.to_stream.read, filename: "Sara-Alert-Format-#{params[:workflow].capitalize}-#{DateTime.now}.xlsx"
    end
  end

  def excel_full_history_patients
    redirect_to(root_url) && return unless current_user.can_export?

    patients = params[:scope] == 'purgeable' ? current_user.viewable_patients.purge_eligible : current_user.viewable_patients
    patient_ids = patients.pluck(:id)
    send_data build_excel_export_for_patients(patient_ids)
  end

  def excel_full_history_patient
    redirect_to(root_url) && return unless current_user.can_export?
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    history = History.new
    history.created_by = current_user.email
    comment = 'User downloaded monitoree\'s data in Excel Export.'
    history.comment = comment
    history.patient = current_user.viewable_patients.find(params[:patient_id])
    history.history_type = 'Monitoree Data Downloaded'
    history.save
    send_data build_excel_export_for_patients([params[:patient_id]])
  end

  def build_excel_export_for_patients(patient_ids)
    patients = current_user.viewable_patients.find(patient_ids)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
        headers = MONITOREES_LIST_HEADERS
        sheet.add_row headers
        patients.each do |patient|
          sheet.add_row [patient.id] + patient.comprehensive_details.values, { types: Array.new(headers.length, :string) }
        end
      end
      p.workbook.add_worksheet(name: 'Assessments') do |sheet|
        assessment_ids = Assessment.where(patient_id: patient_ids).pluck(:id)
        condition_ids = ReportedCondition.where(assessment_id: assessment_ids).pluck(:id)
        # Need to get ALL symptom names and labels (human readable and computer-queryable) since
        # Symptoms may differ over time and bettween sub-jurisdictions but each monitoree columns still need to line up
        symptom_label_and_names = Symptom.where(condition_id: condition_ids).pluck(:label, :name).uniq
        symptom_labels = symptom_label_and_names.collect { |s| s[0] }
        # The full list of symptom names will be used to build the assessment summary where a row can be constructed
        # even for an assessment lacking all possible symptoms
        symptom_names = symptom_label_and_names.collect { |s| s[1] }
        patient_info_headers = %w[patient_id symptomatic who_reported created_at updated_at]
        human_readable_headers = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels
        sheet.add_row human_readable_headers
        patients.each do |patient|
          patient_assessments = patient.assessmenmts_summary_array(patient_info_headers, symptom_names)
          patient_assessments.each do |assessment|
            sheet.add_row assessment, { types: Array.new(human_readable_headers.length, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
        labs = Laboratory.where(patient_id: patient_ids)
        lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
        sheet.add_row lab_headers
        labs.each do |lab|
          sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
        end
      end
      p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
        histories = History.where(patient_id: patient_ids)
        history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
        sheet.add_row history_headers
        histories.each do |history|
          sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end
end
