class MonitorDashboardController < ApplicationController
  before_action :authenticate_user!

  def index

    # Restrict access to monitors only
    return unless current_user.can_view_monitor_dashboard?

    # Load all patients, eager loading assessments
    # TODO: This can be made more performant through SQL if needed
    patients = Patient.all.includes(:latest_assessment)

    # Show all patients that have reported symptoms
    @symptomatic_patients = patients.select { |p| p.latest_assessment.status == 'symptomatic' }

    # Show all patients that have not reported in a timely fashion; this list includes patients who are 1) not
    # symptomatic (we got those above) and 2) who have been in the system long enough to be considered overdue
    # and 3) who have not reported recently

    # TODO: There should be a configurable lag until we care about reporting
    # time_boundary = 24.hours.ago
    time_boundary = 5.minutes.ago
    @non_reporting_patients = patients.select { |p| p.latest_assessment.status != 'symptomatic' && p.created_at < time_boundary && p.latest_assessment.created_at < time_boundary }

    # The rest are asymptomatic patients with a recent report
    @asymptomatic_patients = patients - (@symptomatic_patients + @non_reporting_patients)

  end

end
