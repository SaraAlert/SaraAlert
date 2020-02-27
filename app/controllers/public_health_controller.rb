class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to public health only
    unless current_user.can_view_public_health_dashboard?
      redirect_to root_url and return
    end

    # Load all patients that the current user can see, eager loading assessments
    patients = current_user.viewable_patients.where(monitoring: true).includes(:latest_assessment)

    @closed_patients = current_user.viewable_patients.includes(:latest_assessment).select { |p| p.monitoring == false }

    # Show all patients that have reported symptoms
    @symptomatic_patients = patients.select { |p| p.latest_assessment&.symptomatic }

    # Show all patients that have not reported in a timely fashion; this list includes patients who 1) have
    # been in the system long enough to be considered overdue and 2) are not symptomatic (we got those above)
    # and 3) who have not reported recently

    time_boundary = ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago
    @non_reporting_patients = patients.reject do |p|
      (p.created_at >= time_boundary || # Created more recently than our time boundary, so not expected to have reported yet
       p.latest_assessment&.symptomatic || # Symptomatic, handled in a different list
       (p.latest_assessment && p.latest_assessment.created_at >= time_boundary)) # Reported recently
    end

    # The rest are asymptomatic patients with a recent report or recently added patients
    @asymptomatic_patients = patients - (@symptomatic_patients + @non_reporting_patients)
  end

end
