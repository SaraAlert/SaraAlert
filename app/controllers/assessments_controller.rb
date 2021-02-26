# frozen_string_literal: true

# AssessmentsController: for assessment actions
class AssessmentsController < ApplicationController
  include AssessmentQueryHelper

  def index
    redirect_to(root_url) if ADMIN_OPTIONS['report_mode']
    redirect_to(root_url) && return unless current_user&.can_view_patient_assessments?

    permitted_params = params.permit(:entries, :page, :search, :order, :direction)

    patient_id = params.require(:patient_id)
    search_text = permitted_params[:search]
    sort_order = permitted_params[:order]
    sort_direction = permitted_params[:direction]
    entries = permitted_params[:entries]&.to_i
    page = permitted_params[:page]&.to_i

    patient = current_user.get_patient(patient_id)
    assessments = patient&.assessments
    redirect_to(root_url) && return if patient.nil? || assessments.nil?

    assessments = search(assessments, search_text)
    assessments = sort(assessments, sort_order, sort_direction)
    assessments = paginate(assessments, entries, page)
    assessments = format_for_frontend(assessments)

    render json: assessments
  end

  def new
    permitted_params = params.permit(:patient_submission_token, :unique_identifier, :lang, :initials_age)
    inv_link_url = ADMIN_OPTIONS['report_mode'] ? invalid_link_report_url : invalid_link_url

    # Don't bother with this if the submission token isn't the correct length
    @patient_submission_token = permitted_params[:patient_submission_token].gsub(/[^0-9a-z_-]/i, '')
    redirect_to(inv_link_url) && return if @patient_submission_token.length != 10 && @patient_submission_token.length != 40

    # Don't bother with this if the jurisdiction unique identifier isn't at least 10 characters long
    @unique_identifier = permitted_params[:unique_identifier]&.gsub(/[^0-9a-z_-]/i, '')
    redirect_to(inv_link_url) && return if @unique_identifier.present? && @unique_identifier.length < 10

    # If monitoree, limit number of reports per time period
    if current_user.nil? && AssessmentReceipt.where(submission_token: @patient_submission_token)
                                             .where('created_at >= ?', ADMIN_OPTIONS['reporting_limit'].minutes.ago)
                                             .exists?
      redirect_to(ADMIN_OPTIONS['report_mode'] ? already_reported_report_url : already_reported_url) && return
    end

    # Replace old unique identifier with new unique identifier if applicable
    if @unique_identifier.present? && @unique_identifier.length > 10
      jurisdiction_lookup = JurisdictionLookup.find_by('old_unique_identifier like ?', "#{@unique_identifier}%")
      redirect_to(inv_link_url) && return if jurisdiction_lookup.nil?

      @unique_identifier = jurisdiction_lookup.new_unique_identifier
    end

    # Figure out the jurisdiction to know which symptoms to render
    jurisdiction = if ADMIN_OPTIONS['report_mode']
                     Jurisdiction.find_by(unique_identifier: @unique_identifier)
                   else
                     Patient.find_by(submission_token: get_newest_submission_token(@patient_submission_token))&.jurisdiction
                   end
    redirect_to(inv_link_url) && return if jurisdiction.nil?

    @assessment = Assessment.new
    reporting_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
    @symptoms = reporting_condition.symptoms
    @threshold_hash = jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash
    @translations = @assessment.translations
    @contact_info = jurisdiction.contact_info
    @lang = permitted_params[:lang] if %w[en es es-PR so fr].include?(params[:lang])
    @lang = 'en' if @lang.nil? # Default to english
    @patient_initials = permitted_params[:initials_age]&.upcase&.gsub(/[^a-z]/i, '')
    @patient_age = permitted_params[:initials_age]&.gsub(/[^0-9]/, '')
  end

  def create
    submission_token_from_params = params[:patient_submission_token].gsub(/[^0-9a-z_-]/i, '')

    if ADMIN_OPTIONS['report_mode']
      # patient.submission_token should be length 40 for old submission tokens
      #                                    length 10 for new submission tokens
      #                                    length 34 for execution flow IDs
      token_len = submission_token_from_params.length
      return if token_len != 10 && token_len != 40 && token_len != 34

      # Limit number of reports per time period except for opt_in/opt_out messages
      unless AssessmentReceipt.where(submission_token: submission_token_from_params)
                              .where('created_at >= ?', ADMIN_OPTIONS['reporting_limit'].minutes.ago).exists? &&
             !(params.permit(:response_status)['response_status'].in? %w[opt_out opt_in])
        assessment_placeholder = {}
        assessment_placeholder = assessment_placeholder.merge(params.permit(:error_code).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit(:response_status).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit(:threshold_hash).to_h)
        assessment_placeholder = assessment_placeholder.merge(params.permit({ symptoms: %i[name value type label notes required] }).to_h)
        assessment_placeholder['patient_submission_token'] = submission_token_from_params
        # The generic 'experiencing_symptoms' boolean is used in cases where a user does not specify _which_ symptoms they are experiencing,
        # a value of true will result in an assessment being marked as symptomatic regardless of if symptoms are specified
        unless params.permit(:experiencing_symptoms)['experiencing_symptoms'].blank?
          experiencing_symptoms = (%w[yes yeah].include? params.permit(:experiencing_symptoms)['experiencing_symptoms'].downcase.gsub(/\W/, ''))
          assessment_placeholder['experiencing_symptoms'] = experiencing_symptoms
        end

        # Send the assessment to the queue for consumption
        ProduceAssessmentJob.perform_later assessment_placeholder

        # Save a new receipt and clear out any older ones
        AssessmentReceipt.where(submission_token: submission_token_from_params).delete_all
        assessment_receipt = AssessmentReceipt.new(submission_token: submission_token_from_params)
        assessment_receipt.save
      end
    else
      # If not in report mode, make sure user is authenticated!
      redirect_to(root_url) && return unless current_user&.can_create_patient_assessments?

      # Validate and get patient submission token and redirect if invalid link or already reported
      redirect_to(root_url) && return if params.nil? || params[:patient_submission_token].nil?

      # Lookup new submission token if old one was provided
      newest_submission_token = get_newest_submission_token(submission_token_from_params)
      redirect_to(root_url) && return if newest_submission_token.nil?

      # The patient providing this assessment is identified through the submission_token
      patient = Patient.find_by(submission_token: newest_submission_token)
      redirect_to(root_url) && return unless patient

      threshold_condition_hash = params.permit(:threshold_hash)[:threshold_hash]
      redirect_to(root_url) && return if threshold_condition_hash.blank?

      threshold_condition = ThresholdCondition.find_by(threshold_condition_hash: threshold_condition_hash)
      redirect_to(root_url) && return unless threshold_condition

      reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

      typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

      reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: threshold_condition_hash)

      @assessment = Assessment.new(reported_condition: reported_condition)

      @assessment.patient = patient

      # Determine if a user created this assessment or a monitoree
      @assessment.who_reported = current_user.nil? ? 'Monitoree' : current_user.email

      begin
        reported_condition.transaction do
          reported_condition.save!

          @assessment.symptomatic = @assessment.symptomatic?
          @assessment.save!
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.info(
          "AssessmentsController: Unable to save assessment due to validation error for patient ID: #{patient.id}. " \
          "Error: #{e}"
        )
        return render json: { error: 'Assessment was unable to be saved.' }, status: :bad_request
      end

      # Save a new receipt and clear out any older ones
      AssessmentReceipt.where(submission_token: submission_token_from_params).delete_all
      @assessment_receipt = AssessmentReceipt.new(submission_token: submission_token_from_params)
      @assessment_receipt.save

      # Create history if assessment was created by user
      History.report_created(patient: patient, created_by: current_user.email, comment: "User created a new report (ID: #{@assessment.id}).") if current_user
    end
  end

  def update
    redirect_to(root_url) && return if params.nil? || params[:patient_submission_token].nil?

    submission_token = get_newest_submission_token(params.permit(:patient_submission_token)[:patient_submission_token])
    redirect_to(root_url) && return if submission_token.nil?

    patient = Patient.find_by(submission_token: submission_token)
    redirect_to(root_url) && return if patient.nil?

    redirect_to(root_url) && return unless current_user&.can_edit_patient_assessments?

    assessment = Assessment.find_by(id: params.permit(:id)[:id])
    reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

    typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

    # Figure out the change
    delta = []
    typed_reported_symptoms.each do |symptom|
      new_val = symptom.value
      old_val = assessment.reported_condition&.symptoms&.find_by(name: symptom.name)&.value
      case symptom.type
      when 'BoolSymptom'
        has_changed = old_val != new_val && !old_val.nil? && !new_val.nil?
        delta << "#{symptom.label} (\"#{old_val ? 'Yes' : 'No'}\" to \"#{new_val ? 'Yes' : 'No'}\")" if has_changed
      when 'FloatSymptom', 'IntegerSymptom'
        delta << "#{symptom.label} (\"#{old_val}\" to \"#{new_val}\")" if new_val != old_val
      end
    end

    assessment.reported_condition.symptoms = typed_reported_symptoms
    assessment.symptomatic = assessment.symptomatic?
    # Monitorees can't edit their own assessments, so the last person to touch this assessment was current_user
    assessment.who_reported = current_user.email

    # Attempt to save and continue; else if failed redirect to index
    return unless assessment.save

    comment = 'User updated an existing report (ID: ' + assessment.id.to_s + ').'
    comment += ' Symptom updates: ' + delta.join(', ') + '.' unless delta.empty?
    History.report_updated(patient: patient, created_by: current_user.email, comment: comment)
  end

  # For report mode instances, this is the default landing
  def landing
    redirect_to(root_url) && return unless ADMIN_OPTIONS['report_mode']
  end

  # The monitoree already reported. Give them an update
  def already_reported; end

  protected

  def get_newest_submission_token(submission_token)
    return submission_token if submission_token.length != 40

    PatientLookup.find_by(old_submission_token: submission_token)&.new_submission_token
  end
end
