# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExportHelper

  before_action :authenticate_user!

  def csv
    # Verify permissions
    redirect_to(root_url) && return unless current_user.can_export?

    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    headers = params[:type] == 'linelist' ? LINELIST_HEADERS : COMPREHENSIVE_HEADERS

    # Grab patients to export based on monitoring type
    patients = current_user.viewable_patients.where(isolation: params[:workflow] == 'isolation').where(purged: false)

    # Build CSV
    csv_result = CSV.generate(headers: true) do |csv|
      csv << headers
      patients.find_each(batch_size: 500) do |patient|
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
    patients = current_user.viewable_patients.where(isolation: params[:workflow] == 'isolation').where(purged: false)

    # Build Excel
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees') do |sheet|
        headers = COMPREHENSIVE_HEADERS
        sheet.add_row headers
        patient_statuses = get_patient_statuses(patients)
        patients.find_each(batch_size: 500) do |patient|
          patient_details = patient.comprehensive_details
          patient_details[:status] = patient_statuses[patient.id] || ''
          sheet.add_row patient_details.values, { types: Array.new(headers.length, :string) }
        end
      end
      send_data p.to_stream.read, filename: "Sara-Alert-Format-#{params[:workflow].capitalize}-#{DateTime.now}.xlsx"
    end
  end

  def excel_full_history_patients
    redirect_to(root_url) && return unless current_user.can_export?

    patients = params[:scope] == 'purgeable' ? current_user.viewable_patients.purge_eligible : current_user.viewable_patients.where(purged: false)
    send_data build_excel_export_for_patients(patients)
  end

  def excel_full_history_patient
    redirect_to(root_url) && return unless current_user.can_export?
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    patients = current_user.viewable_patients.where(id: params[:patient_id])
    return if patients.empty?

    history = History.new
    history.created_by = current_user.email
    comment = 'User downloaded monitoree\'s data in Excel Export.'
    history.comment = comment
    history.patient = patients.first
    history.history_type = 'Monitoree Data Downloaded'
    history.save
    send_data build_excel_export_for_patients(patients)
  end

  def build_excel_export_for_patients(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
        headers = MONITOREES_LIST_HEADERS
        sheet.add_row headers
        patient_statuses = get_patient_statuses(patients)
        patients.find_each(batch_size: 500) do |patient|
          patient_details = patient.comprehensive_details
          patient_details[:status] = patient_statuses[patient.id] || ''
          sheet.add_row [patient.id] + patient_details.values, { types: Array.new(headers.length, :string) }
        end
      end
      p.workbook.add_worksheet(name: 'Assessments') do |sheet|
        assessment_ids = Assessment.where(patient_id: patients.last&.id).pluck(:id)
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
        patients.find_each(batch_size: 500) do |patient|
          patient_assessments = patient.assessmenmts_summary_array(patient_info_headers, symptom_names)
          patient_assessments.each do |assessment|
            sheet.add_row assessment, { types: Array.new(human_readable_headers.length, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
        labs = Laboratory.where(patient_id: patients.pluck(:id))
        lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
        sheet.add_row lab_headers
        labs.find_each(batch_size: 500) do |lab|
          sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
        end
      end
      p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
        histories = History.where(patient_id: patients.pluck(:id))
        history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
        sheet.add_row history_headers
        histories.find_each(batch_size: 500) do |history|
          sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def get_patient_statuses(patients)
    statuses = {
      closed: patients.monitoring_closed.pluck(:id),
      purged: patients.purged.pluck(:id),
      pui: patients.under_investigation.pluck(:id),
      symptomatic: patients.symptomatic.pluck(:id),
      asymptomatic: patients.asymptomatic.pluck(:id),
      non_reporting: patients.non_reporting.pluck(:id),
      isolation_asymp_non_test_based: patients.asymp_non_test_based.pluck(:id),
      isolation_symp_non_test_based: patients.symp_non_test_based.pluck(:id),
      isolation_test_based: patients.test_based.pluck(:id),
      isolation_reporting: patients.isolation_reporting.pluck(:id),
      isolation_non_reporting: patients.isolation_non_reporting.pluck(:id)
    }
    patient_statuses = {}
    statuses.each do |status, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = status&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end
end
