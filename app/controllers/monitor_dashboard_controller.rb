class MonitorDashboardController < ApplicationController
  before_action :authenticate_user!

  def index

    # Restrict access to monitors only
    redirect_to root_url unless current_user.can_view_monitor_dashboard?

    # Load all patients, eager loading assessments
    # TODO: This can be made more performant through SQL if needed
    patients = Patient.all.includes(:latest_assessment)

    # Show all patients that have reported symptoms
    @symptomatic_patients = patients.select { |p| p.latest_assessment&.status == 'symptomatic' }

    # Show all patients that have not reported in a timely fashion; this list includes patients who 1) have
    # been in the system long enough to be considered overdue and 2) are not symptomatic (we got those above)
    # and 3) who have not reported recently

    # TODO: There should be a configurable lag until we care about reporting
    time_boundary = 2.minutes.ago
    @non_reporting_patients = patients.reject do |p|
      (p.created_at >= time_boundary || # Created more recently than our time boundary, so not expected to have reported yet
       p.latest_assessment&.status == 'symptomatic' || # Symptomatic, handled in a different list
       (p.latest_assessment && p.latest_assessment.created_at >= time_boundary)) # Reported recently
    end

    # The rest are asymptomatic patients with a recent report or recently added patients
    @asymptomatic_patients = patients - (@symptomatic_patients + @non_reporting_patients)

  end

end
