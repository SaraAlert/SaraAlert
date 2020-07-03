# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :default
  include ImportExportHelper

  def perform(user_id, export_type)
    user = User.find_by(id: user_id)
    return if user.nil?

    # Construct export
    case export_type
    when 'csv_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = "Sara-Alert-Linelist-Exposure-#{DateTime.now}.csv"
      data = csv_line_list(patients)
    when 'csv_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Linelist-Isolation-#{DateTime.now}.csv"
      data = csv_line_list(patients)
    when 'sara_format_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = "Sara-Alert-Format-Exposure-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
    when 'sara_format_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Format-Isolation-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
    when 'full_history_all'
      patients = user.viewable_patients.where(purged: false)
      filename = "Sara-Alert-Full-Export-#{DateTime.now}.xlsx"
      data = build_excel_export_for_patients(patients)
    when 'full_history_purgeable'
      patients = user.viewable_patients.purge_eligible
      filename = "Sara-Alert-Purge-Eligible-Export-#{DateTime.now}.xlsx"
      data = build_excel_export_for_patients(patients)
    end
    return if data.blank?

    # Construct download object from export data and save (overwrite any of existing type for this user)
    existing_download = user.downloads.find_by(export_type: export_type)
    existing_download&.destroy!
    download = Download.new(user_id: user_id, contents: data, filename: filename, lookup: SecureRandom.uuid, export_type: export_type)

    if ActiveRecord::Base.logger.formatter.nil?
      download.save!
    else
      ActiveRecord::Base.logger.silence do
        download.save!
      end
    end

    # Send an email to user
    UserMailer.download_email(user, export_type, download.lookup).deliver_later
  end

  def csv_line_list(patients)
    package = CSV.generate(headers: true) do |csv|
      csv << LINELIST_HEADERS
      patient_statuses = get_patient_statuses(patients)
      patients.find_in_batches(batch_size: 500) do |patients_group|
        linelists = get_linelists(patients_group, patient_statuses)
        patients_group.each do |patient|
          csv << linelists[patient.id].values
        end
      end
    end
    Base64.encode64(package)
  end

  def sara_alert_format(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees') do |sheet|
        sheet.add_row COMPREHENSIVE_HEADERS
        patient_statuses = get_patient_statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = get_comprehensive_details(patients_group, patient_statuses)
          patients_group.each do |patient|
            sheet.add_row comprehensive_details[patient.id].values, { types: Array.new(COMPREHENSIVE_HEADERS.length, :string) }
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def build_excel_export_for_patients(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
        headers = MONITOREES_LIST_HEADERS
        sheet.add_row headers
        patient_statuses = get_patient_statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = get_comprehensive_details(patients_group, patient_statuses)
          patients_group.each do |patient|
            sheet.add_row [patient.id] + comprehensive_details[patient.id].values, { types: Array.new(MONITOREES_LIST_HEADERS.length, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Assessments') do |sheet|
        # headers and all unique symptoms
        symptom_labels = patients.joins(assessments: [{ reported_condition: :symptoms }]).select('symptoms.label').distinct.pluck('symptoms.label').sort
        sheet.add_row ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort

        # assessments sorted by patients
        patients.find_in_batches(batch_size: 500) do |patients_group|
          assessments = Assessment.where(patient_id: patients_group.pluck(:id))
          conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
          symptoms = Symptom.where(condition_id: conditions.pluck(:id))

          # construct hash containing symptoms by assessment_id
          conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
                            .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
          symptoms.each do |symptom|
            conditions_hash[symptom[:condition_id]][:symptoms][symptom[:label]] = symptom.value
          end
          assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]

          # combine symptoms with assessment summary
          assessment_summary_arrays = assessments.order(:patient_id, :id).pluck(:id, :patient_id, :symptomatic, :who_reported, :created_at, :updated_at)
          assessment_summary_arrays.each do |assessment_summary_array|
            symptoms_hash = assessments_hash[assessment_summary_array[0]]
            symptoms_array = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s }
            row = assessment_summary_array[1..-1].concat(symptoms_array)
            sheet.add_row row, { types: Array.new(row.length, :string) }
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
end
