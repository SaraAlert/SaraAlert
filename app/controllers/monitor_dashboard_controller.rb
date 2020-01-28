class MonitorDashboardController < ApplicationController

  def index

    # Show all patients that have reported symptoms
    @symptomatic_patients = Patient.joins(:assessments).where(assessments: { status: 'symptomatic' }).distinct

    # Show all patients that have not reported in a timely fashion
    # TODO: There should be a 24 hour lag until we care about reporting
    # time_boundary = Time.zone.now - 24.hours
    time_boundary = Time.zone.now - 5.minutes
    @non_reporting_patients = Patient.where('patients.created_at < ?', time_boundary).where.not(id: Assessment.select(:patient_id).where('assessments.created_at > ?', time_boundary))

    # We could show all patients that have not reported symptoms
    # @asymptomatic_patients = Patient.joins(:assessments).where(assessments: { status: 'asymptomatic' }).distinct

  end

end
