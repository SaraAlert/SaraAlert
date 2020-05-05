# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  before_action :authenticate_user!

  def csv_isolation
    csv(true)
  end

  def csv(isolation = false)
    redirect_to(root_url) && return unless current_user.can_export?

    headers = ['Monitoree', 'Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth',
               'End of Monitoring', 'Risk Level', 'Monitoring Plan', 'Latest Report', 'Transferred At',
               'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At',
               'Transferred From', 'Transferred To', 'Expected Purge Date']

    # Grab patients to export based on type
    if params[:type] == 'symptomatic'
      patients = current_user.viewable_patients.symptomatic.where(isolation: isolation)
    elsif params[:type] == 'asymptomatic'
      patients = current_user.viewable_patients.asymptomatic.where(isolation: isolation)
    elsif params[:type] == 'nonreporting'
      patients = current_user.viewable_patients.non_reporting.where(isolation: isolation)
    elsif params[:type] == 'closed'
      patients = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: isolation)
    elsif params[:type] == 'transferred'
      patients = current_user.jurisdiction.transferred_patients.where(isolation: isolation)
    elsif params[:type] == 'all'
      patients = current_user.viewable_patients.where(isolation: isolation)
    end

    # Do nothing if issue with request/permissions
    redirect_to(root_url) && return if patients.nil?

    # Build CSV
    csv_result = CSV.generate(headers: true) do |csv|
      csv << headers
      patients.each do |patient|
        p = patient.linelist.values
        p[0] = p[0][:name]
        csv << p
      end
    end

    send_data csv_result, filename: "Sara-Alert-Line-List-#{params[:type]}-#{DateTime.now}.csv"
  end

  def csv_comprehensive_isolation
    csv_comprehensive(true)
  end

  def csv_comprehensive(isolation = false)
    redirect_to(root_url) && return unless current_user.can_export?

    headers = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
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

    # Grab patients to export based on type
    if params[:type] == 'symptomatic'
      patients = current_user.viewable_patients.symptomatic.where(isolation: isolation)
    elsif params[:type] == 'asymptomatic'
      patients = current_user.viewable_patients.asymptomatic.where(isolation: isolation)
    elsif params[:type] == 'nonreporting'
      patients = current_user.viewable_patients.non_reporting.where(isolation: isolation)
    elsif params[:type] == 'closed'
      patients = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: isolation)
    elsif params[:type] == 'transferred'
      patients = current_user.jurisdiction.transferred_patients.where(isolation: isolation)
    elsif params[:type] == 'all'
      patients = current_user.viewable_patients.where(isolation: isolation)
    end

    # Do nothing if issue with request/permissions
    redirect_to(root_url) && return if patients.nil?

    # Build CSV
    csv_result = CSV.generate(headers: true) do |csv|
      csv << headers
      patients.each do |patient|
        p = patient.comprehensive_details.values
        csv << p
      end
    end

    send_data csv_result, filename: "Sara-Alert-Format-#{params[:type]}-#{DateTime.now}.csv"
  end

  def full_history_all_monitorees
    patients = current_user.viewable_patients
    patient_ids = patients.pluck(:id)
    send_data build_excel_export_for_patients(patient_ids)
  end

  def full_history_purge_eligible_monitorees
    patients = current_user.viewable_patients.purge_eligible
    patient_ids = patients.pluck(:id)
    send_data build_excel_export_for_patients(patient_ids)
  end

  def full_history_single_monitoree
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
        headers = ['Patient ID', 'First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
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
                   'Contact of Known Case?', 'Contact of Known Case ID', 'Travel from Affected Country or Area?',
                   'Was in Health Care Facility With Known Cases?', 'Health Care Facility with Known Cases Name',
                   'Laboratory Personnel?', 'Laboratory Personnel Facility Name', 'Health Care Personnel?', 'Health Care Personnel Facility Name',
                   'Crew on Passenger or Cargo Flight?', 'Member of a Common Exposure Cohort?', 'Common Exposure Cohort Name',
                   'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status']
        sheet.add_row headers
        patients.each do |patient|
          sheet.add_row [patient.id] + patient.comprehensive_details.values
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
        assessment_headers = %w[patient_id symptomatic who_reported created_at updated_at]
        human_readable_headers = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels
        sheet.add_row human_readable_headers
        patients.each do |patient|
          patient_assessments = patient.assessmenmts_summary_array(assessment_headers, symptom_names)
          patient_assessments.each do |assessment|
            sheet.add_row assessment
          end
        end
      end
      p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
        labs = Laboratory.where(patient_id: patient_ids)
        lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
        sheet.add_row lab_headers
        labs.each do |lab|
          patient_id = lab.patient_id
          lab_type = lab.lab_type
          lab_specimen_collection = lab.specimen_collection
          lab_report = lab.report
          lab_result = lab.result
          lab_created_at = lab&.created_at || ''
          lab_updated_at = lab&.updated_at || ''
          lab_row = [patient_id, lab_type, lab_specimen_collection, lab_report, lab_result, lab_created_at, lab_updated_at]
          sheet.add_row lab_row
        end
      end
      p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
        histories = History.where(patient_id: patient_ids)
        history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
        sheet.add_row history_headers
        histories.each do |history|
          patient_id = history.patient_id
          comment = history&.comment || ''
          created_by = history&.created_by || ''
          history_type = history&.history_type || ''
          history_created_at = history&.created_at || ''
          history_updated_at = history&.updated_at || ''
          history_row = [patient_id, comment, created_by, history_type, history_created_at, history_updated_at]
          sheet.add_row history_row
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end
end
