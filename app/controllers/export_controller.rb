class ExportController < ApplicationController
  before_action :authenticate_user!

  def csv
    unless current_user.can_export?
      redirect_to root_url and return
    end

    # Grab patients to export based on type
    if params[:type] == 'symptomatic'
      patients = current_user.viewable_patients.symptomatic
    elsif params[:type] == 'asymptomatic'
      patients = current_user.viewable_patients.asymptomatic
    elsif params[:type] == 'nonreporting'
      patients = current_user.viewable_patients.non_reporting
    elsif params[:type] == 'closed'
      patients = current_user.viewable_patients.monitoring_closed
    end

    # Do nothing if issue with request/permissions
    if patients.nil?
      redirect_to root_url and return
    end

    # Build CSV
    csv_result = CSV.generate(headers: true) do |csv|
      csv << ['Monitoree', 'Assigned Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth',
              'End of Monitoring', 'Risk Level', 'Monitoring Plan', 'Latest Report']
      patients.each do |patient|
        p = patient.linelist.values
        p[0] = p[0][:name]
        csv << p
      end
    end

    send_data csv_result, filename: "Sara-Alert-#{params[:type]}-#{DateTime.now}.csv"
  end
end
