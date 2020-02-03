class MonitorDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to monitors only
    redirect_to root_url unless current_user.can_view_monitor_dashboard?

    # Load all patients, eager loading assessments
    # TODO: This can be made more performant through SQL if needed
    patients = Patient.all.includes(:latest_assessment)

    # Show all patients that have reported symptoms
    @symptomatic_patients = patients.select { |p| p.latest_assessment&.symptomatic }

    # Show all patients that have not reported in a timely fashion; this list includes patients who 1) have
    # been in the system long enough to be considered overdue and 2) are not symptomatic (we got those above)
    # and 3) who have not reported recently

    # TODO: There should be a configurable lag until we care about reporting
    time_boundary = 1.minutes.ago
    @non_reporting_patients = patients.reject do |p|
      (p.created_at >= time_boundary || # Created more recently than our time boundary, so not expected to have reported yet
       p.latest_assessment&.symptomatic || # Symptomatic, handled in a different list
       (p.latest_assessment && p.latest_assessment.created_at >= time_boundary)) # Reported recently
    end

    # The rest are asymptomatic patients with a recent report or recently added patients
    @asymptomatic_patients = patients - (@symptomatic_patients + @non_reporting_patients)

    # Populate the information needed for the statistical portion of the dashboard

    # Check how many reported or not today
    # TODO: Ensure that date edge conditions are handled correctly
    reported_today = patients.select { |p| p.latest_assessment&.created_at&.to_date == Date.today }
    reported_today_count = reported_today.length
    not_yet_reported_count = patients.length - reported_today_count

    # Generate counts per day
    dates = patients.map { |p| p.created_at.to_date }.uniq.sort
    date_map = {}
    dates.each_with_index { |d, i| date_map[d] = i + 1 }
    patient_count_by_day = Hash.new(0)
    patients.each { |p| patient_count_by_day[date_map[p.created_at.to_date]] += 1 }

    # Distribution by state for map
    patient_count_by_state = Hash.new(0)
    patients.each { |p| patient_count_by_state[p.monitored_address_state] += 1 }

    @stats = {
      system_subjects: Patient.count,
      system_subjects_last_24: Patient.where('created_at >= ?', Time.now - 1.day).count,
      system_assessmets: Assessment.count,
      system_assessmets_last_24: Assessment.where('created_at >= ?', Time.now - 1.day).count,
      subject_status: [
        { name: 'Asymptomatic', value: @asymptomatic_patients.length },
        { name: 'Non-Reporting', value: @non_reporting_patients.length },
        { name: 'Symptomatic', value: @symptomatic_patients.length },
        { name: 'Confirmed', value: Patient.where(confirmed_case: true).count }
      ],
      reporting_summmary: [
        { name: 'Reported Today', value: reported_today_count },
        { name: 'Not Yet Reported', value: not_yet_reported_count }
      ],
      monitoring_distribution_by_day: patient_count_by_day,
      monitoring_distribution_by_state: patient_count_by_state
    }
  end

end
