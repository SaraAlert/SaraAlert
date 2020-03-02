class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to analytics users only
    unless current_user.can_view_analytics?
      redirect_to root_url and return
    end

    # Stats for enrollers
    if current_user.has_role?(:enroller)
      @stats = {
        system_subjects: Patient.count,
        system_subjects_last_24: Patient.where('created_at >= ?', Time.now - 1.day).count,
        system_assessmets: Assessment.count,
        system_assessmets_last_24: Assessment.where('created_at >= ?', Time.now - 1.day).count,
        user_subjects: Patient.where(creator_id: current_user.id).count,
        user_subjects_last_24: Patient.where(creator_id: current_user.id).where('created_at >= ?', Time.now - 1.day).count,
        user_assessments: Patient.where(creator_id: current_user.id).joins(:assessments).count,
        user_assessments_last_24: Patient.where(creator_id: current_user.id).joins(:assessments).where('assessments.created_at >= ?', Time.now - 1.day).count
      }
    end

    # Stats for public health & analysts
    if current_user.has_role?(:public_health) || current_user.has_role?(:public_health_enroller) || current_user.has_role?(:analyst)
      # Load all patients that the current user can see, eager loading assessments
      patients = current_user.viewable_patients.where(monitoring: true).includes(:latest_assessment)

      # Patients that are not being monitored
      closed_patients = current_user.viewable_patients.where(monitoring: false)

      # Show all patients that have reported symptoms
      symptomatic_patients = patients.select { |p| p.latest_assessment&.symptomatic }

      # Show all patients that have not reported in a timely fashion; this list includes patients who 1) have
      # been in the system long enough to be considered overdue and 2) are not symptomatic (we got those above)
      # and 3) who have not reported recently

      time_boundary = ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago
      non_reporting_patients = patients.reject do |p|
        (p.created_at >= time_boundary || # Created more recently than our time boundary, so not expected to have reported yet
        p.latest_assessment&.symptomatic || # Symptomatic, handled in a different list
        (p.latest_assessment && p.latest_assessment.created_at >= time_boundary)) # Reported recently
      end

      # The rest are asymptomatic patients with a recent report or recently added patients
      asymptomatic_patients = patients - (symptomatic_patients + non_reporting_patients)

      # Populate the information needed for the statistical portion of the dashboard, organizing the results in
      # the format required by the graphs for display

      # TODO: These were implemented rapidly without considering performance, clarity of implementation, or edge
      # cases like date boundaries, and should be reviewed and likely refactored

      # Check how many reported or not today
      reported_today = patients.select { |p| p.latest_assessment&.created_at&.to_date == Date.today }
      reported_today_count = reported_today.length
      not_yet_reported_count = patients.length - reported_today_count

      # Generate counts per day
      dates = patients.map { |p| p.created_at.to_date }.uniq.sort

      # This obviously isn't the most efficient way to obtain this data
      symptomatic_patient_count_by_state_and_day = []
      total_patient_count_by_state_and_day = []
      dates.each_with_index { | d, i |
        symptomatic_patient_count_by_state_and_day << {day: d}
        total_patient_count_by_state_and_day << {day: d}
        states = ['Alabama', 'Alaska', 'American Samoa', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'District of Columbia', 'Federated States of Micronesia', 'Florida', 'Georgia', 'Guam', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Marshall Islands', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Northern Mariana Islands', 'Ohio', 'Oklahoma', 'Oregon', 'Palau', 'Pennsylvania', 'Puerto Rico', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virgin Island', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming']
        states.each { | state |
          count1 = Assessment.joins(:patient).where('assessments.created_at::date = ?', d).where(symptomatic: true, 'patients.monitored_address_state' => state).count()
          symptomatic_patient_count_by_state_and_day[i][state] = count1
          count2 = Assessment.joins(:patient).where('assessments.created_at::date = ?', d).where('patients.monitored_address_state' => state).count()
          total_patient_count_by_state_and_day[i][state] = count2
        }
      }
      date_map = {}
      dates.each_with_index { |d, i| date_map[d] = i + 1 }
      patient_count_by_day = Hash.new(0)
      patients.each { |p| patient_count_by_day[date_map[p.created_at.to_date]] += 1 }
      patient_count_by_day_array = []
      patient_count_by_day.each { |day, count| patient_count_by_day_array << { day: day, cases: count } }
      patient_count_by_day_array.sort_by!	{ |count| count[:day] }

      # Distribution by state for map
      patient_count_by_state = Hash.new(0)
      patients.each { |p| patient_count_by_state[p.monitored_address_state] += 1 }

      # Symptomatic or unsymptomatic per day
      symptomatic_assessments_by_day = Hash.new(0)
      asymptomatic_assessments_by_day = Hash.new(0)
      Assessment.where(patient: patients).find_each do |a|
        if a.symptomatic
          symptomatic_assessments_by_day[a.created_at.to_date] += 1
        else
          asymptomatic_assessments_by_day[a.created_at.to_date] += 1
        end
      end
      assessment_result_by_day_array = []
      (symptomatic_assessments_by_day.keys | asymptomatic_assessments_by_day.keys).sort.each do |date|
        assessment_result_by_day_array << {
          'name' => date.to_s,
          'Symptomatic Assessments' => symptomatic_assessments_by_day[date],
          'Asymptomatic Assessments' => asymptomatic_assessments_by_day[date]
        }
      end

      @stats = {
        system_subjects: patients.count,
        system_subjects_last_24: patients.where('created_at >= ?', Time.now - 1.day).count,
        system_assessmets: Assessment.where(patient: patients).count,
        system_assessmets_last_24: Assessment.where(patient: patients).where('created_at >= ?', Time.now - 1.day).count,
        subject_status: [
          { name: 'Asymptomatic', value: asymptomatic_patients.length },
          { name: 'Non-Reporting', value: non_reporting_patients.length },
          { name: 'Symptomatic', value: symptomatic_patients.length },
          { name: 'Closed', value: closed_patients.count }
        ],
        reporting_summmary: [
          { name: 'Reported Today', value: reported_today_count },
          { name: 'Not Yet Reported', value: not_yet_reported_count }
        ],
        monitoring_distribution_by_day: patient_count_by_day_array,
        monitoring_distribution_by_state: patient_count_by_state,
        symptomatic_patient_count_by_state_and_day: symptomatic_patient_count_by_state_and_day,
        total_patient_count_by_state_and_day: total_patient_count_by_state_and_day,
        assessment_result_by_day:	assessment_result_by_day_array
      }
    end
  end

end
