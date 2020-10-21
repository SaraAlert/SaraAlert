# frozen_string_literal: true

# AssessmentsController: for assessment actions
class AssessmentsController < ApplicationController
  def index; end

  def new
    # Validate and get patient submission token and redirect if invalid link or already reported
    @patient_submission_token = check_and_get_patient_submission_token(invalid_link_url,
                                                                       ADMIN_OPTIONS['report_mode'] ? already_reported_report_url : already_reported_url)
    return if @patient_submission_token.nil?

    # Don't bother with this if the jurisdiction unique identifier isn't at least 10 characters long
    @unique_identifier = params.permit(:unique_identifier)[:unique_identifier]&.gsub(/[^0-9A-Za-z_-]/i, '')
    redirect_to(invalid_link_url) && return if @unique_identifier.present? && @unique_identifier.length < 10

    # Replace old unique identifier with new unique identifier if applicable
    if @unique_identifier.present? && @unique_identifier.length > 10
      jurisdiction_lookup = JurisdictionLookup.where('old_unique_identifier like ?', "#{@unique_identifier}%").first
      redirect_to(invalid_link_url) && return if jurisdiction_lookup.nil?

      @unique_identifier = jurisdiction_lookup.new_unique_identifier
    end

    # Figure out the jurisdiction to know which symptoms to render
    jurisdiction = if ADMIN_OPTIONS['report_mode']
                     Jurisdiction.where('BINARY unique_identifier = ?', @unique_identifier).first
                   else
                     # Try looking up jurisdiction by patient (@patient_submission_token here should be the new version)
                     Patient.where('BINARY submission_token = ?', @patient_submission_token).first&.jurisdiction
                   end
    redirect_to(invalid_link_url) && return if jurisdiction.nil?

    @assessment = Assessment.new
    reporting_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
    @symptoms = reporting_condition.symptoms
    @threshold_hash = jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash
    @translations = @assessment.translations
    @contact_info = jurisdiction.contact_info
    @lang = params.permit(:lang)[:lang] if %w[en es es-PR so fr].include?(params[:lang])
    @lang = 'en' if @lang.nil? # Default to english
    @patient_initials = params.permit(:initials_age)[:initials_age]&.upcase&.gsub(/[^A-Z]/i, '')
    @patient_age = params.permit(:initials_age)[:initials_age]&.gsub(/[^0-9]/i, '')
  end

  def create
    if ADMIN_OPTIONS['report_mode']
      # Validate and get patient submission token and redirect if invalid link or already reported
      @patient_submission_token = check_and_get_patient_submission_token(nil, nil)
      return if @patient_submission_token.nil?

      assessment_placeholder = {}
      assessment_placeholder = assessment_placeholder.merge(params.permit(:response_status).to_h)
      assessment_placeholder = assessment_placeholder.merge(params.permit(:threshold_hash).to_h)
      assessment_placeholder = assessment_placeholder.merge(params.permit({ symptoms: %i[name value type label notes required] }).to_h)
      assessment_placeholder['patient_submission_token'] = @patient_submission_token
      # The generic 'experiencing_symptoms' boolean is used in cases where a user does not specify _which_ symptoms they are experiencing,
      # a value of true will result in an assessment being marked as symptomatic regardless of if symptoms are specified
      unless params.permit(:experiencing_symptoms)['experiencing_symptoms'].blank?
        experiencing_symptoms = (%w[yes yeah].include? params.permit(:experiencing_symptoms)['experiencing_symptoms'].downcase.gsub(/\W/, ''))
        assessment_placeholder['experiencing_symptoms'] = experiencing_symptoms
      end

      # Send the assessment to the queue for consumption
      ProduceAssessmentJob.perform_later assessment_placeholder

      # Clear out any old receipts
      AssessmentReceipt.where('BINARY submission_token = ?', @patient_submission_token).delete_all

      # Save a new receipt
      assessment_receipt = AssessmentReceipt.new(submission_token: @patient_submission_token)
      assessment_receipt.save
    else
      # If not in report mode, make sure user is authenticated!
      redirect_to(root_url) && return unless current_user&.can_create_patient_assessments?

      # Validate and get patient submission token and redirect if invalid link or already reported
      @patient_submission_token = check_and_get_patient_submission_token(root_url, root_url)
      return if @patient_submission_token.nil?

      # The patient providing this assessment is identified through the submission_token
      patient = Patient.where('BINARY submission_token = ?', @patient_submission_token).first
      redirect_to(root_url) && return unless patient

      threshold_condition_hash = params.permit(:threshold_hash)[:threshold_hash]
      threshold_condition = ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first
      redirect_to(root_url) && return unless threshold_condition

      reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

      typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

      reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: threshold_condition_hash)

      @assessment = Assessment.new(reported_condition: reported_condition)
      @assessment.symptomatic = @assessment.symptomatic?

      @assessment.patient = patient

      # Determine if a user created this assessment or a monitoree
      if current_user.nil?
        @assessment.who_reported = 'Monitoree'
        @assessment.save
        # Save a new receipt and clear out any older ones
        AssessmentReceipt.where('BINARY submission_token = ?', @patient_submission_token).delete_all
        assessment_receipt = AssessmentReceipt.new(submission_token: @patient_submission_token)
        assessment_receipt.save
      else
        @assessment.who_reported = current_user.email
        @assessment.save
        # Save a new receipt and clear out any older ones
        AssessmentReceipt.where('BINARY submission_token = ?', @patient_submission_token).delete_all
        assessment_receipt = AssessmentReceipt.new(submission_token: @patient_submission_token)
        assessment_receipt.save

        History.report_created(patient: patient, created_by: current_user.email, comment: "User created a new report. ID: #{@assessment.id}")
      end

      redirect_to(patient_assessments_url)
    end
  end

  def update
    @patient_submission_token = check_and_get_patient_submission_token(root_url, nil)
    return if @patient_submission_token.nil?

    redirect_to root_url unless current_user&.can_edit_patient_assessments?
    patient = Patient.where('BINARY submission_token = ?', params.permit(:patient_submission_token)[:patient_submission_token]).first
    assessment = Assessment.find_by(id: params.permit(:id)[:id])
    reported_symptoms_array = params.permit({ symptoms: %i[name value type label notes required] }).to_h['symptoms']

    typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)

    # Figure out the change
    delta = []
    typed_reported_symptoms.each do |symptom|
      new_val = symptom.bool_value
      old_val = assessment.reported_condition&.symptoms&.find_by(name: symptom.name)&.bool_value
      if new_val.present? && old_val.present? && new_val != old_val
        delta << symptom.name + '=' + (new_val ? 'Yes' : 'No')
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
    redirect_to(patient_assessments_url) && return
  end

  # For report mode instances, this is the default landing
  def landing
    redirect_to(root_url) && return unless ADMIN_OPTIONS['report_mode']
  end

  # The monitoree already reported. Give them an update
  def already_reported; end

  protected

  def check_and_get_patient_submission_token(invalid_link_url, already_reported_url)
    # Params and token existence
    return if invalid_link_url.nil? && (params.nil? || params[:patient_submission_token].nil?)
    redirect_to(invalid_link_url) && return if !invalid_link_url.nil? && (params.nil? || params[:patient_submission_token].nil?)

    # Token validation
    patient_submission_token = params[:patient_submission_token].gsub(/[^0-9A-Za-z_-]/i, '')
    return if invalid_link_url.nil? && patient_submission_token.length != 10 && patient_submission_token.length != 40
    redirect_to(invalid_link_url) && return if !invalid_link_url.nil? && patient_submission_token.length != 10 && patient_submission_token.length != 40

    # Replace old submission token with new submission token if applicable
    if patient_submission_token.length == 40
      patient_lookup = PatientLookup.where(old_submission_token: patient_submission_token).first
      if patient_lookup.nil?
        return if invalid_link_url.nil?
        redirect_to(invalid_link_url) && return unless url.nil?
      end

      patient_submission_token = patient_lookup.new_submission_token
    end

    # Redirect and return if already reported
    if already_reported_url.present? && AssessmentReceipt.where('BINARY submission_token = ?', patient_submission_token)
                                                         .where('created_at >= ?', ADMIN_OPTIONS['reporting_limit'].minutes.ago)
                                                         .exists?
      redirect_to(already_reported_url) && return
    end

    patient_submission_token
  end
end
