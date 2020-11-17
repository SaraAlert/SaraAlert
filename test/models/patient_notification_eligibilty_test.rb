# frozen_string_literal: true

require 'test_case'


# If HoH preferred contact method is unknown, opt-out, or blank
# are they still eligible for notifications for dependents? How are they notified?
# - no notification

# What is HoH pauses notifications but has a dependent that is eligible for notifications?
# - they do not recieve notifications for dependents when HoH has notifications paused.

# What if notifications are paused for a dependent?
# - doesn't matter because notification is dependending on the HoH

# What if a report for an otherwise eligible dependent has already been submitted in the past day?
# - Right now they will still get a notification
# - Later we may want to change this.


# What if a reminder has already been sent in the past day for an otherwise eligible dependent?
# - Right now they will still get a notification
# - Later we may want to change this.

# Reminder sent < 12 hours ago means system already sent a reminder today?
# - This is intended

# What determines if a patient is in the exposure workflow?
# * seems like (isolation: false, continuous exposure: false,
# * and seems that monitoring date passed is determined by
# * (last_exposure_date: > 14 days ago) OR (last_exposure_date: nil, created_at: > 14 days ago))
# - isolation: true is the ONLY thing that determines if someone is in the exposure workflow

# When do patients get purged?
# - see purge_job.rb and :purge_eligible scope

# Does (continuous_exposure: true) exclusively determine continuous montioring?
# - YES

# How does `isolation` affect notification eligibility? In the flowchart?
# * seems like it is an automatic NO for "is in exposure workflow"?
# - see above

# What if a patient under continuous monitoring has already submitted a report in the past day?
# - continuous monitoring DOES NOT override

# What if a patient under continuous monitoring has already been sent a reminder in the past day?
# - continuous monitoring DOES NOT override

# Can (monitoring: false) exclusively determine if the record is closed?
# - YES

# What is the isolation workflow? (Referenced in Patient model scopes)
# * it seems like it is just if not in exposure workflow on the flowchart.
# - You are EITHER in the exposure workflow or the isolation workflow

# Data dictionary?
# - https://saraalert.org/wp-content/uploads/2020/11/Sara_Alert_Data_Dictionary_1.16.pdf

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
      assert_equal 0, Patient.reminder_eligible.count
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
      assert_equal 0, Patient.reminder_eligible.count
    end
  end

  # ------------------------------------------ #
  # Not in exposure workflow eligibility flows #
  # ------------------------------------------ #

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # Is in isolation?                     => Yes
  # Is record closed?                    => Yes
  # :NOT ELIGIBLE:
  test 'non-household patient record has been closed' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        isolation: true,
        purged: false,
        monitoring: false,
        closed_at: 1.hour.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
    end
  end

  # In household?                        => No
  # Preferred reporting method?          => Email link, SMS link, Telephone, SMS texts
  # Notifications paused?                => No
  # Is in isolation?                     => Yes
  # Is record closed?                    => No
  # :ELIGIBLE:
  test 'non-household patient under continuous monitoring' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        isolation: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 25.hours.ago
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: 15.days.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count

      # Created outside montoring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
        last_date_of_exposure: 5.days.ago,
        purged: false,
        monitoring: false,
        closed_at: 1.day.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count


      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: false,
        closed_at: 1.day.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
        last_date_of_exposure: 5.days.ago,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count


      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: 5.days.ago,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
        last_date_of_exposure: 5.days.ago,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      assert Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 0, Patient.reminder_eligible.count
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
          last_date_of_exposure: 5.days.ago,
          purged: false,
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
        assert_equal 1, Patient.reminder_eligible.count

        # Created within moniroring period without exposure date
        Patient.destroy_all
        patient = create(:patient,
          created_at: 5.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: nil,
          purged: false,
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
        assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: nil
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count

      # Sent a reminder > 12 hours ago
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 25.hours.ago
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: true
      )
      dependent = create(:patient, responder: patient)
      assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
      assert_equal 1, Patient.reminder_eligible.count
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
          last_date_of_exposure: 5.days.ago,
          purged: false,
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        dependent = create(:patient, responder: patient)
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
        assert_equal 1, Patient.reminder_eligible.count

        # Created within moniroring period without exposure date
        Patient.destroy_all
        patient = create(:patient,
          created_at: 5.days.ago,
          preferred_contact_method: report_method,
          pause_notifications: false,
          last_date_of_exposure: nil,
          purged: false,
          monitoring: true,
          closed_at: nil,
          continuous_exposure: false,
          last_assessment_reminder_sent: last_reminder_date
        )
        dependent = create(:patient, responder: patient)
        create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: (Time.now.getlocal('-04:00').beginning_of_day - 10.hours)
      )
        assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
        assert_equal 1, Patient.reminder_eligible.count
      end
    end
  end

  # ------------------------ #
  # HoH NO eligibility flows #
  # ------------------------ #

  def do_all_in_exposure_workflow_past_monitoring_date_case(patient)
    # Dependent in exposure workflow  => true
    # Dependent past monitoring date  => true
    # :NOT ELIGIBLE:
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 15.days.ago,
      isolation: false,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 0, Patient.reminder_eligible.count
    dependent.destroy

    dependent = create(:patient,
      responder: patient,
      created_at: 15.days.ago,
      last_date_of_exposure: nil,
      isolation: false,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 0, Patient.reminder_eligible.count
    dependent.destroy

    # Dependent in exposure workflow  => true
    # Dependent past monitoring date  => false
    # :NOT ELIGIBLE:
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      isolation: false,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy

    dependent = create(:patient,
      responder: patient,
      created_at: 5.days.ago,
      last_date_of_exposure: nil,
      isolation: false,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy
  end

  def do_continuous_exposure_case(patient)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: nil,
      isolation: false,
      continuous_exposure: true,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy
  end

  def do_dependent_isolation_cases(patient)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      isolation: true,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy
  end

  def do_dependent_monitoring_period_cases(patient)

  end

  def do_closed_line_list_cases(patient)
    # reporter on closed line list   => true
    # dependent on closed line list  => false
    # :ELIGIBLE
    patient.update(monitoring: false, closed_at: 1.day.ago)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy

    # reporter on closed line list   => false
    # dependent on closed line list  => false
    # :ELIGIBLE
    patient.update(monitoring: true, closed_at: nil)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      continuous_exposure: false,
      purged: false,
      monitoring: true,
      closed_at: nil
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy

    # reporter on closed line list   => false
    # dependent on closed line list  => true
    # :ELIGIBLE
    patient.update(monitoring: true, closed_at: nil)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      continuous_exposure: false,
      purged: false,
      monitoring: false,
      closed_at: 1.day.ago
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy

    # reporter on closed line list   => true
    # dependent on closed line list  => true
    # :ELIGIBLE
    patient.update(monitoring: false, closed_at: 1.day.ago)
    dependent = create(:patient,
      responder: patient,
      last_date_of_exposure: 5.days.ago,
      continuous_exposure: false,
      purged: false,
      monitoring: false,
      closed_at: 1.day.ago
    )
    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 1, Patient.reminder_eligible.count
    dependent.destroy
  end

  def do_currently_ineligible(patient)
    assert Patient.reminder_eligible.find_by(id: patient.id).nil?
    assert_equal 0, Patient.reminder_eligible.count
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
        do_currently_ineligible(patient)
        do_dependent_monitoring_period_cases(patient)
        do_dependent_isolation_cases(patient)
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
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: false,
        closed_at: 1.hour.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        last_date_of_exposure: 5.days.ago,
        purged: false,
        monitoring: false,
        closed_at: 1.day.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      # Created within moniroring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 5.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: false,
        closed_at: 1.day.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        last_date_of_exposure: 15.days.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      # Created within montoring period without exposure date
      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 10.days.ago,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false
      )
      create(:assessment,
        patient: patient,
        symptomatic: false,
        created_at: Time.now.getlocal('-04:00').beginning_of_day
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
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
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: nil,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)

      Patient.destroy_all
      patient = create(:patient,
        created_at: 15.days.ago,
        preferred_contact_method: report_method,
        pause_notifications: false,
        last_date_of_exposure: 10.days.ago,
        purged: false,
        monitoring: true,
        closed_at: nil,
        continuous_exposure: false,
        last_assessment_reminder_sent: 11.hours.ago
      )
      do_currently_ineligible(patient)
      do_dependent_monitoring_period_cases(patient)
      do_dependent_isolation_cases(patient)
      do_all_in_exposure_workflow_past_monitoring_date_case(patient)
      do_continuous_exposure_case(patient)
      do_closed_line_list_cases(patient)
    end
  end
end