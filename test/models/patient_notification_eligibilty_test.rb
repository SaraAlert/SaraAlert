# frozen_string_literal: true

require 'test_case'

# rubocop:disable Metrics/ClassLength
class PatientNotificationEligibilityTest < ActiveSupport::TestCase
  def setup
    @default_purgeable_after = ADMIN_OPTIONS['purgeable_after']
    @default_weekly_purge_warning_date = ADMIN_OPTIONS['weekly_purge_warning_date']
    @default_weekly_purge_date = ADMIN_OPTIONS['weekly_purge_date']
  end

  def teardown
    ADMIN_OPTIONS['purgeable_after'] = @default_purgeable_after
    ADMIN_OPTIONS['weekly_purge_warning_date'] = @default_weekly_purge_warning_date
    ADMIN_OPTIONS['weekly_purge_date'] = @default_weekly_purge_date
  end

  # ----------------------------------------------- #
  # Non-Eligible reporting method eligibility flows #
  # ----------------------------------------------- #

  # In household?                        => No
  # Preferred reporting method?          => Unknown, Opt-Out, Blank
  # :NOT ELIGIBLE:
  test 'non-household patient unusable reporting method' do
    ['Unknown', 'Opt-out', '', nil].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # -------------------------------------- #
  # Paused notifications eligibility flows #
  # -------------------------------------- #

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient paused notifications' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method:
        report_method, pause_notifications: true
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # ------------------------------------------ #
  # Not in exposure workflow eligibility flows #
  # ------------------------------------------ #

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient record has been closed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.hour.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => Yes
  # :ELIGIBLE:
  test 'non-household patient under continuous monitoring' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient already submitted symptoms in past 24 hours' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient already sent a reminder today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 23.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => No
  # :ELIGIBLE:
  test 'non-household patient not sent a reminder yet today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 25.hours.ago
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # -------------------------------------- #
  # In exposure workflow eligibility flows #
  # -------------------------------------- #

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date passed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 20.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 15.days.ago  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?

      # Created within montoring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date not passed and record closed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Exposure date within monitoring period
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.day.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?


      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.day.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => Yes
  # :ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date not passed and under continuous monitoring' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Exposure date within monitoring period
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?


      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date not passed and already submitted in past day' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Exposure date within monitoring period
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date not passed and already sent reminder today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Exposure date within monitoring period
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 23.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 23.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => No
  # :ELIGIBLE:
  test 'non-household patient in exposure workflow monitoring date not passed and not sent a reminder yet today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      [25.hours.ago, nil].each do |last_reminder_date|
        # Exposure date within monitoring period
        Patient.destroy_all
        patient = create(:patient,
          created_at: 15.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?

        # Created within moniroring period without exposure date
        Patient.destroy_all
        patient = create(:patient,
          created_at: 5.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      end
    end
  end

  # ------------------------- #
  # HoH YES eligibility flows #
  # ------------------------- #

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => Yes
  # :ELIGIBLE:
  test 'HoH is under continuous monitoring' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => No
  # :ELIGIBLE:
  test 'HoH has not been sent a reminder yet today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Never sent a reminder
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: nil
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?

      # Sent a reminder > 24 hours ago
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 25.hours.ago
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => Yes
  # :ELIGIBLE:
  test 'HoH in exposure workflow and under continuous monitoring' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => No
  # :ELIGIBLE:
  test 'HoH in exposure workflow and no sent a reminder yet today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      [25.hours.ago, nil].each do |last_reminder_date|
        # Exposure date within monitoring period
        Patient.destroy_all
        patient = create(:patient,
          created_at: 15.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        dependent = create(:patient, responder: patient)
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?

        # Created within moniroring period without exposure date
        Patient.destroy_all
        patient = create(:patient,
          created_at: 5.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        dependent = create(:patient, responder: patient)
        create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      end
    end
  end

  # ------------------------ #
  # HoH NO eligibility flows #
  # ------------------------ #

  def do_all_in_exposure_workflow_past_monitoring_date_case(patient)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 15.days.ago
    )
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    dependent.destroy
  end

  def do_continuous_exposure_case(patient)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      continuous_exposure: true
    )
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    dependent.destroy
  end

  def do_closed_line_list_cases(patient)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 18.days.ago,
      continuous_exposure: false,
      monitoring: true,
      closed_at: nil
    )
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    dependent.destroy
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Unknown, Opt-Out, Blank
  # :NOT ELIGIBLE:
  test 'HoH has unusable reporting method' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      ['Unknown', 'Opt-out', '', nil].each do |report_method|
        Patient.destroy_all
        patient = create(:patient,
          created_at: 15.days.ago,
          preferred_contact_method: report_method
        )
        do_continuous_exposure_case(patient)
        do_closed_line_list_cases(patient)
      end
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => Yes
  # :NOT ELIGIBLE:
  test 'HoH paused notifications' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: true
      )
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => Yes
  # :NOT ELIGIBLE:
  test 'HoH record is closed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.hour.ago
      )
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => Yes
  # :NOT ELIGIBLE:
  test 'HoH submitted in the past 24 hours' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => Yes
  # :NOT ELIGIBLE:
  test 'HoH already sent a reminder today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 24.hours.ago
      )
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => Yes
  # :NOT ELIGIBLE:
  test 'HoH in exposure workflow and record closed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      # Exposure date within monitoring period
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 5.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.day.ago
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: false,
        closed_at: 1.day.ago
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => Yes
  # :NOT ELIGIBLE:
  test 'HoH in exposure workflow and monitoring date passed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 15.days.ago  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      # Created within montoring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => Yes
  # :NOT ELIGIBLE:
  test 'HoH in exposure workflow and submitted symptoms in last 24 hours' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 13.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 10.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment, patient: patient, symptomatic: false, created_at: 23.hours.ago)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # In household?                        => Yes
  # Is head of household?                => Yes
  # HoH is eligible to be notified?      => Don't Know
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # In exposure workflow?                => Yes
  # Monitoring date passed?              => No
  # Is record closed?                    => No
  # Continuous monitoring?               => No
  # Submitted symptoms in the past day?  => No
  # Already sent a reminder today?       => Yes
  # :NOT ELIGIBLE:
  test 'HoH in exposure workflow and already sent a reminder today' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 13.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 23.hours.ago
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 10.days.ago,  # ASK IF THIS DETERMINES THE EXPOSURE WORKFLOW
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 23.hours.ago
      )
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end

  # ------------------------- #
  # HOH eligibility Flowchart #
  # ------------------------- #

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => Yes
  # # All HH members past monitoring period?  => Yes
  # # :NOT ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => Yes
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => Yes
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => Yes
  # # Any HH members on continuous exposure?  => Yes
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => Yes
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => Yes
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => Yes
  # # :NOT ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => Yes
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => Yes
  # # :NOT ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => Yes
  # # :NOT ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => Yes
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => No
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => Yes
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => No
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end

  # # In household?                           => Yes
  # # Is head of household?                   => Yes
  # # HoH is eligible to be notified?         => No
  # # All HH members in exposure workflow     => No
  # # All HH members past monitoring period?  => No
  # # Any HH members on continuous exposure?  => No
  # # All HH members on closed line list?     => No
  # # :ELIGIBLE:
  # test '' do
  #   Patient.destroy_all

  # end
end