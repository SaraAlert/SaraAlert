# frozen_string_literal: true

namespace :demo do
  desc 'Configure the database for demo use'
  task setup: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    #####################################

    print 'Gathering jurisdictions...'

    jurisdictions = {}

    jurisdictions[:usa] = Jurisdiction.where(name: 'USA').first
    jurisdictions[:state1] = Jurisdiction.where(name: 'State 1').first
    jurisdictions[:state2] = Jurisdiction.where(name: 'State 2').first
    jurisdictions[:county1] = Jurisdiction.where(name: 'County 1').first
    jurisdictions[:county2] = Jurisdiction.where(name: 'County 2').first
    jurisdictions[:county3] = Jurisdiction.where(name: 'County 3').first
    jurisdictions[:county4] = Jurisdiction.where(name: 'County 4').first

    if jurisdictions.has_value?(nil)
      puts ' Demonstration jurisdictions were not found! Make sure to run `bundle exec rake admin:import_or_update_jurisdictions` with the demonstration jurisdictions.yml'
      exit(1)
    end

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    enroller1 = User.create(email: 'state1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller2 = User.create(email: 'localS1C1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller3 = User.create(email: 'localS1C2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county2], force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller4 = User.create(email: 'state2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state2], force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller5 = User.create(email: 'localS2C3_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county3], force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller6 = User.create(email: 'localS2C4_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county4], force_password_change: false, authy_enabled: false, authy_enforced: false)

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    ph1 = User.create(email: 'state1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
    ph2 = User.create(email: 'localS1C1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph3 = User.create(email: 'localS1C2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county2], force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph4 = User.create(email: 'state2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state2], force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph5 = User.create(email: 'localS2C3_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county3], force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph6 = User.create(email: 'localS2C4_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county4], force_password_change: false, authy_enabled: false, authy_enforced: false)

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    phe1 = User.create(email: 'epi_enroller_all@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
    phe2 = User.create(email: 'state1_epi_enroller@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    admin1 = User.create(email: 'admin1@example.com', password: '1234567ab!', role: Roles::ADMIN, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false)

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    analyst1 = User.create(email: 'analyst_all@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false)
    analyst2 = User.create(email: 'state1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false)
    analyst3 = User.create(email: 'localS1C1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:county1], force_password_change: false, authy_enabled: false, authy_enforced: false)

    puts ' done!'

    #####################################

    print 'Creating super users...'

    super_user1 = User.create(email: 'usa_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
    super_user2 = User.create(email: 'state1_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)

    puts ' done!'

    #####################################

    print 'Creating contract tracer users...'

    contact_tracer1 = User.create(email: 'usa_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)
    contact_tracer2 = User.create(email: 'state1_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:state1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true)

    puts ' done!'

    #####################################

    print 'Creating demo Doorkeeper OAuth application...'

    OauthApplication.create(name: 'demo', redirect_uri: 'http://localhost:3000/redirect', scopes: 'user/Patient.* user/Observation.read user/QuestionnaireResponse.read', uid: 'demo-oauth-app-uid', secret: 'demo-oauth-app-secret')

    puts ' done!'

    #####################################

    printf("\n")
  end

  desc 'Add synthetic patient/monitoree data to the database for an initial time period in days'
  task populate: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    # Remove analytics that are created in admin:import_or_update_jurisdictions task
    Analytic.delete_all

    days = (ENV['DAYS'] || 14).to_i
    num_patients_today = (ENV['COUNT'] || 25).to_i
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all
    assigned_users = Hash[jurisdictions.pluck(:id).map {|id| [id, (1..999_999).to_a.sample(10)]}]

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))

    days.times do |day|
      today = Date.today - (days - (day + 1)).days
      # Create the patients for this day
      printf("Simulating day #{day + 1} (#{today}):\n")

      # Calculate number of days ago
      days_ago = days - day

      # Populate patients, assessments, laboratories, transfers, histories, analytics
      demo_populate_day(today, num_patients_today, days_ago, jurisdictions, assigned_users, cache_analytics, counties)

      # Cases increase 10-20% every day
      num_patients_today += (num_patients_today * (0.1 + (rand / 10))).round

      printf("\n")
    end
  end

  desc 'Add synthetic patient/monitoree data to the database for a single day (today)'
  task update: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_patients_today = (ENV['COUNT'] || 25).to_i * 20
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all
    assigned_users = Hash[jurisdictions.map {|jur| [jur[:id], jur.assigned_users]}]

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))

    printf("Simulating today\n")

    demo_populate_day(Date.today, num_patients_today, 0, jurisdictions, assigned_users, cache_analytics, counties)
  end

  def demo_populate_day(today, num_patients_today, days_ago, jurisdictions, assigned_users, cache_analytics, counties)
    # Transactions speeds things up a bit
    ActiveRecord::Base.transaction do
      # Patients created before today
      existing_patients = Patient.monitoring_open.where('created_at < ?', today)

      # Histories to be created today
      histories = []

      # Create patients
      patient_histories = demo_populate_patients(today, num_patients_today, days_ago, jurisdictions, assigned_users, counties)
      histories = histories.concat(patient_histories)

      # Create assessments
      assessment_histories = demo_populate_assessments(today, days_ago, existing_patients, jurisdictions)
      histories = histories.concat(assessment_histories)

      # Create laboratories
      laboratory_histories = demo_populate_laboratories(today, days_ago, existing_patients)
      histories = histories.concat(laboratory_histories)

      # Create close contacts
      close_contacts_histories = demo_populate_close_contacts(today, days_ago, existing_patients)
      histories = histories.concat(close_contacts_histories)

      # Create transfers
      transfer_histories = demo_populate_transfers(today, existing_patients, jurisdictions, assigned_users)
      histories = histories.concat(transfer_histories)

      # Create close contacts
      close_contacts_histories = demo_populate_close_contacts(today, days_ago, existing_patients)
      histories = histories.concat(close_contacts_histories)

      # Create contact attempts
      contact_attempt_histories = demo_populate_contact_attempts(today, existing_patients)
      histories = histories.concat(contact_attempt_histories)

      # Create histories
      demo_populate_histories(today, histories)
    end

    # Needs to be in a separate transaction
    ActiveRecord::Base.transaction do
      # Update linelist fields
      demo_populate_linelists
    end

    # Cache analytics
    demo_cache_analytics(today, cache_analytics)
  end

  def demo_populate_patients(today, num_patients_today, days_ago, jurisdictions, assigned_users, counties)
    territory_names = ['American Samoa', 'District of Columbia', 'Federated States of Micronesia', 'Guam', 'Marshall Islands', 'Northern Mariana Islands',
                       'Palau', 'Puerto Rico', 'Virgin Islands'].freeze

    printf("Generating monitorees...")
    patients = []
    histories = []
    num_patients_today.times do |i|
      printf("\rGenerating monitoree #{i + 1} of #{num_patients_today}...")
      patient = Patient.new()

      # Identification
      sex = Faker::Gender.binary_type
      sexualOrientations = ['Straight or Heterosexual', 'Lesbian, Gay, or Homosexual', 'Bisexual', 'Another', 'Choose not to disclose', 'Don’t know', 'Unknown'].freeze
      patient[:sex] = rand < 0.9 ? sex : 'Unknown' if rand < 0.9
      patient[:gender_identity] = ValidationHelper::VALID_PATIENT_ENUMS[:gender_identity].sample if rand < 0.7
      patient[:sexual_orientation] = ValidationHelper::VALID_PATIENT_ENUMS[:sexual_orientation].sample if rand < 0.6
      patient[:first_name] = "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
      patient[:middle_name] = "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
      patient[:date_of_birth] = Faker::Date.birthday(min_age: 1, max_age: 85)
      patient[:age] = ((Date.today - patient[:date_of_birth]) / 365.25).round
      %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander].sample(rand(0..4)).each { |race| patient[race] = true }
      patient[:ethnicity] = rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino'
      patient[:primary_language] = rand < 0.7 ? 'English' : Faker::Nation.language
      patient[:secondary_language] = Faker::Nation.language if rand < 0.4
      patient[:interpretation_required] = rand < 0.15
      patient[:nationality] = Faker::Nation.nationality if rand < 0.6
      patient[:user_defined_id_statelocal] = "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:user_defined_id_cdc] = Faker::Code.npi if rand < 0.2
      patient[:user_defined_id_nndss] = Faker::Code.rut if rand < 0.2

      # Contact Information
      patient[:preferred_contact_method] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_method].sample
      patient[:preferred_contact_time] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_time].sample if patient[:preferred_contact_method] != 'E-mailed Web Link' && rand < 0.6
      patient[:primary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:preferred_contact_method] != 'E-mailed Web Link' || rand < 0.5
      patient[:primary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:primary_telephone_type].sample if patient[:primary_telephone]
      patient[:secondary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:primary_telephone] && rand < 0.5
      patient[:secondary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:secondary_telephone_type].sample if patient[:secondary_telephone]
      patient[:email] = "#{rand(1000000000..9999999999)}fake@example.com" if patient[:preferred_contact_method] == 'E-mailed Web Link' || rand < 0.5

      # Address
      if rand < 0.8
        patient[:address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:address_city] = Faker::Address.city if rand < 0.95
        patient[:address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
        patient[:address_line_2] = Faker::Address.secondary_address if rand < 0.4
        patient[:address_zip] = Faker::Address.zip_code if rand < 0.95
        if rand < 0.85 && counties.key?(patient[:address_state])
          patient[:address_county] = rand < 0.95 ? counties[patient[:address_state]].sample : Faker::Address.community
        end
        if rand < 0.7
          patient[:monitored_address_line_1] = patient[:address_line_1]
          patient[:monitored_address_city] = patient[:address_city]
          patient[:monitored_address_state] = patient[:address_state]
          patient[:monitored_address_line_2] = patient[:address_line_2]
          patient[:monitored_address_zip] = patient[:address_zip]
          patient[:monitored_address_county] = patient[:address_county]
        else
          patient[:monitored_address_line_1] = Faker::Address.street_address if rand < 0.95
          patient[:monitored_address_city] = Faker::Address.city if rand < 0.95
          patient[:monitored_address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
          patient[:monitored_address_line_2] = Faker::Address.secondary_address if rand < 0.4
          patient[:monitored_address_zip] = Faker::Address.zip_code if rand < 0.95
          if rand < 0.85 && counties.key?(patient[:monitored_address_state])
            patient[:monitored_address_county] = rand < 0.95 ? counties[patient[:monitored_address_state]].sample : Faker::Address.community
          end
        end
      else
        patient[:foreign_address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:foreign_address_city] = Faker::Nation.capital_city if rand < 0.95
        patient[:foreign_address_country] = Faker::Address.country if rand < 0.95
        patient[:foreign_address_line_2] = Faker::Address.secondary_address if rand < 0.6
        patient[:foreign_address_zip] = Faker::Address.zip_code if rand < 0.95
        patient[:foreign_address_line_3] = Faker::Address.secondary_address if patient[:foreign_address_line_2] && rand < 0.4
        patient[:foreign_address_state] = Faker::Address.community if rand < 0.7
        patient[:foreign_monitored_address_line_1] = Faker::Address.street_address if rand < 0.95
        patient[:foreign_monitored_address_city] = Faker::Nation.capital_city if rand < 0.95
        patient[:foreign_monitored_address_state] = rand < 0.9 ? counties.keys.sample : territory_names[rand(territory_names.count)] if rand < 0.95
        patient[:foreign_monitored_address_line_2] = Faker::Address.secondary_address if rand < 0.4
        patient[:foreign_monitored_address_zip] = Faker::Address.zip_code if rand < 0.95
        if rand < 0.85 && counties.key?(patient[:foreign_monitored_address_state])
          patient[:foreign_monitored_address_county] = rand < 0.95 ? counties[patient[:foreign_monitored_address_state]].sample : Faker::Address.community
        end
      end

      # Arrival information
      if rand < 0.7
        patient[:port_of_origin] = Faker::Address.city
        patient[:date_of_departure] = today - (rand < 0.3 ? 1.day : 0.days)
        patient[:source_of_report] = ValidationHelper::VALID_PATIENT_ENUMS[:source_of_report].sample if rand < 0.7
        patient[:source_of_report_specify] = Faker::TvShows::SiliconValley.invention if patient[:source_of_report] == 'Other'
        patient[:flight_or_vessel_number] = "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}"
        patient[:flight_or_vessel_carrier] = "#{Faker::Name.first_name} Airlines"
        patient[:port_of_entry_into_usa] = Faker::Address.city
        patient[:date_of_arrival] = today
        patient[:travel_related_notes] = Faker::GreekPhilosophers.quote if rand < 0.3
      end

      # Additional planned travel
      if rand < 0.3
        if rand < 0.7
          patient[:additional_planned_travel_type] = 'Domestic'
          patient[:additional_planned_travel_destination_state] = rand > 0.5 ? Faker::Address.state : territory_names[rand(territory_names.count)]
        else
          patient[:additional_planned_travel_type] = 'International'
          patient[:additional_planned_travel_destination_country] = Faker::Address.country
        end
        patient[:additional_planned_travel_destination] = Faker::Address.city
        patient[:additional_planned_travel_port_of_departure] = Faker::Address.city
        patient[:additional_planned_travel_start_date] = today + rand(6).days
        patient[:additional_planned_travel_end_date] = patient[:additional_planned_travel_start_date] + rand(10).days
        patient[:additional_planned_travel_related_notes] = Faker::ChuckNorris.fact if rand < 0.4
      end

      # Potential Exposure Info
      patient[:isolation] = days_ago > 10 ? rand < 0.9 : rand < 0.4
      if patient[:isolation]
        patient[:symptom_onset] = today - rand(10).days
        patient[:user_defined_symptom_onset] = true
      else
        patient[:continuous_exposure] = rand < 0.3
        patient[:last_date_of_exposure] = today - rand(5).days unless patient[:continuous_exposure]
      end
      patient[:potential_exposure_location] = Faker::Address.city if rand < 0.7
      patient[:potential_exposure_country] = Faker::Address.country if rand < 0.8
      patient[:exposure_notes] = Faker::Games::LeagueOfLegends.quote if rand < 0.5
      if rand < 0.85
        patient[:contact_of_known_case] = rand < 0.3
        patient[:contact_of_known_case_id] = Faker::Code.ean if patient[:contact_of_known_case] && rand < 0.5
        patient[:member_of_a_common_exposure_cohort] = rand < 0.35
        patient[:member_of_a_common_exposure_cohort_type] = Faker::Superhero.name if patient[:member_of_a_common_exposure_cohort] && rand < 0.5
        patient[:travel_to_affected_country_or_area] = rand < 0.1
        patient[:laboratory_personnel] = rand < 0.25
        patient[:laboratory_personnel_facility_name] = Faker::Company.name if patient[:laboratory_personnel] && rand < 0.5
        patient[:healthcare_personnel] = rand < 0.2
        patient[:healthcare_personnel_facility_name] = Faker::FunnyName.name if patient[:healthcare_personnel] && rand < 0.5
        patient[:crew_on_passenger_or_cargo_flight] = rand < 0.25
        patient[:was_in_health_care_facility_with_known_cases] = rand < 0.15
        patient[:was_in_health_care_facility_with_known_cases_facility_name] = Faker::GreekPhilosophers.name if patient[:was_in_health_care_facility_with_known_cases] && rand < 0.15
      end
      patient[:jurisdiction_id] = jurisdictions.sample[:id]
      patient[:assigned_user] = assigned_users[patient[:jurisdiction_id]].sample if rand < 0.8
      patient[:exposure_risk_assessment] = ValidationHelper::VALID_PATIENT_ENUMS[:exposure_risk_assessment].sample
      patient[:monitoring_plan] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_plan].sample

      # Other fields populated upon enrollment
      patient[:submission_token] = SecureRandom.urlsafe_base64[0, 10]
      patient[:creator_id] = User.all.select { |u| u.role?('enroller') }.sample[:id]
      patient[:responder_id] = 1 # temporarily set responder_id to 1 to pass schema validation
      patient_ts = create_fake_timestamp(today, today)
      patient[:created_at] = patient_ts
      patient[:updated_at] = patient_ts

      # Update monitoring status
      patient[:extended_isolation] = today + rand(10).days if patient[:isolation] && rand < 0.3
      patient[:case_status] = patient[:isolation] ? ['Confirmed', 'Probable'].sample : ['Suspect', 'Unknown', 'Not a Case', nil].sample
      patient[:monitoring] = rand < 0.95
      patient[:closed_at] = patient[:updated_at] unless patient[:monitoring]
      patient[:monitoring_reason] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_reason].sample if patient[:monitoring].nil?
      patient[:public_health_action] = patient[:isolation] || rand < 0.8 ? 'None' : ValidationHelper::VALID_PATIENT_ENUMS[:public_health_action].sample
      patient[:pause_notifications] = rand < 0.1
      patient[:last_assessment_reminder_sent] = today - rand(7).days if rand < 0.3

      patients << patient
    end

    Patient.import! patients
    new_patients = Patient.where('created_at >= ?', today)
    new_patients.update_all('responder_id = id')

    # 10-20% of patients are managed by a household member
    new_children = new_patients.sample(new_patients.count * rand(10..20) / 100)
    new_parents = new_patients - new_children
    new_children_updates =  new_children.map { |new_child|
      parent = new_parents.sample
      { responder_id: parent[:id], jurisdiction_id: parent[:jurisdiction_id] }
    }
    Patient.update(new_children.map { |p| p[:id] }, new_children_updates)

    new_patients.each do |patient|
      # enrollment
      histories << History.new(
        patient_id: patient[:id],
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: 'User enrolled monitoree.',
        history_type: 'Enrollment',
        created_at: patient[:created_at],
        updated_at: patient[:created_at],
      )
      # monitoring status
      histories << History.new(
        patient_id: patient[:id],
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: "User changed monitoring status to \"Not Monitoring\". Reason: #{patient[:monitoring_reason]}",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:monitoring]
      # exposure risk assessment
      histories << History.new(
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: "User changed exposure risk assessment to \"#{patient[:exposure_risk_assessment]}\".",
        patient_id: patient[:id],
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:exposure_risk_assessment].nil?
      # case status
      histories << History.new(
        patient_id: patient[:id],
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: "User changed case status to \"#{patient[:case_status]}\", and chose to \"Continue Monitoring in Isolation Workflow\".",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:case_status].nil?
      # public health action
      histories << History.new(
        patient_id: patient[:id],
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: "User changed latest public health action to \"#{patient[:public_health_action]}\".",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:public_health_action] == 'None'
      # pause notifications
      histories << History.new(
        patient_id: patient[:id],
        created_by: User.all.select { |u| u.role?('enroller') }.sample[:email],
        comment: "User paused notifications for this monitoree.",
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at],
      ) unless patient[:pause_notifications] == false
    end
    printf(" done.\n")

    return histories
  end

  def demo_populate_assessments(today, days_ago, existing_patients, jurisdictions)
    printf("Generating assessments...")
    assessments = []
    assessment_receipts = []
    histories = []
    patient_jur_ids_and_sub_tokens = existing_patients.pluck(:id, :jurisdiction_id, :submission_token).sample(existing_patients.count * rand(55..60) / 100)
    patient_jur_ids_and_sub_tokens.each_with_index do |(patient_id, jur_id, sub_token), index|
      printf("\rGenerating assessment #{index+1} of #{patient_jur_ids_and_sub_tokens.length}...")
      assessment_ts = create_fake_timestamp(today, today)
      assessments << Assessment.new(
        patient_id: patient_id,
        symptomatic: false,
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      assessment_receipts << AssessmentReceipt.new(
        submission_token: sub_token,
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: 'Sara Alert System',
        comment: "Sara Alert sent a report reminder to this monitoree via Telephone call.",
        history_type: History::HISTORY_TYPES[:report_reminder],
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: User.all.select { |u| u.role?('public_health') }.sample[:email],
        comment: "User created a new report.",
        history_type: 'Report Created',
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
    end

    # Create assessment receipts and replace any existing ones
    AssessmentReceipt.where(submission_token: assessment_receipts.map{ |assessment_receipt| assessment_receipt[:submission_token] }).destroy_all
    AssessmentReceipt.import! assessment_receipts
    Assessment.import! assessments
    printf(" done.\n")

    # Get symptoms for each jurisdiction
    threshold_conditions = {}
    jurisdictions.each do |jurisdiction|
      threshold_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
      threshold_conditions[jurisdiction[:id]] = {
        hash: threshold_condition[:threshold_condition_hash],
        symptoms: threshold_condition.symptoms
      }
    end

    printf("Generating condition for assessments...")
    reported_conditions = []
    new_assessments = Assessment.where('assessments.created_at >= ?', today).joins(:patient)
    new_assessments.each_with_index do |assessment, index|
      printf("\rGenerating condition for assessment #{index+1} of #{new_assessments.length}...")
      reported_conditions << ReportedCondition.new(
        assessment_id: assessment[:id],
        threshold_condition_hash: threshold_conditions[assessment.patient.jurisdiction_id][:hash],
        created_at: assessment[:created_at],
        updated_at: assessment[:updated_at]
      )
    end
    ReportedCondition.import! reported_conditions
    printf(" done.\n")

    # Create earlier symptom onset dates to meet isolation symptomatic non test based requirement
    if days_ago > 10
      symptomatic_assessments = new_assessments.where('patient_id % 4 <> 0').sample(new_assessments.count * rand(75..80) / 100)
    else
      symptomatic_assessments = new_assessments.where('patient_id % 4 <> 0').sample(new_assessments.count * rand(20..25) / 100)
    end

    printf("Generating symptoms for assessments...")
    symptoms = []
    new_reported_conditions = ReportedCondition.where('conditions.created_at >= ?', today).joins(assessment: :reported_condition)
    new_reported_conditions.each_with_index do |reported_condition, index|
      printf("\rGenerating symptoms for assessment #{index+1} of #{new_reported_conditions.length}...")
      threshold_symptoms = threshold_conditions[reported_condition.assessment.patient.jurisdiction_id][:symptoms]
      symptomatic_assessment = symptomatic_assessments.include?(reported_condition.assessment)
      num_symptomatic_symptoms = ((rand ** 2) * threshold_symptoms.length).floor # creates a distribution favored towards fewer symptoms
      symptomatic_symptoms = symptomatic_assessment ? threshold_symptoms.to_a.shuffle[1..num_symptomatic_symptoms] : []

      threshold_symptoms.each do |threshold_symptom|
        symptomatic_symptom = %w[fever used-a-fever-reducer].include?(threshold_symptom[:name]) && rand < 0.8 ? false : symptomatic_symptoms.include?(threshold_symptom)
        symptoms << Symptom.new(
          condition_id: reported_condition[:id],
          name: threshold_symptom[:name],
          label: threshold_symptom[:label],
          notes: threshold_symptom[:notes],
          type: threshold_symptom[:type],
          bool_value: threshold_symptom[:type] == 'BoolSymptom' ? symptomatic_symptom : nil,
          float_value: threshold_symptom[:type] == 'FloatSymptom' ? ((threshold_symptom.value || 0) + rand(10.0) * (symptomatic_symptom ? -1 : 1)) : nil,
          int_value: threshold_symptom[:type] == 'IntSymptom' ? ((threshold_symptom.value || 0 )+ rand(10) * (symptomatic_symptom ? -1 : 1)) : nil,
          created_at: reported_condition[:created_at],
          updated_at: reported_condition[:updated_at]
        )
      end
    end
    Symptom.import! symptoms
    printf(" done.\n")

    printf("Updating symptomatic statuses...")
    assessment_symptomatic_statuses = {}
    patient_symptom_onset_date_updates = {}
    symptomatic_patients_without_symptom_onset_ids = Patient.where(id: symptomatic_assessments.pluck(:patient_id), symptom_onset: nil).ids
    symptomatic_assessments.each_with_index do |assessment, index|
      printf("\rUpdating symptomatic status #{index+1} of #{symptomatic_assessments.length}...")
      if assessment.symptomatic?
        assessment_symptomatic_statuses[assessment[:id]] = { symptomatic: true }
        if symptomatic_patients_without_symptom_onset_ids.include?(assessment[:patient_id])
          patient_symptom_onset_date_updates[assessment[:patient_id]] = { symptom_onset: assessment[:created_at] }
        end
      end
    end
    Assessment.update(assessment_symptomatic_statuses.keys, assessment_symptomatic_statuses.values)
    Patient.update(patient_symptom_onset_date_updates.keys, patient_symptom_onset_date_updates.values)
    printf(" done.\n")

    return histories
  end

  def demo_populate_laboratories(today, days_ago, existing_patients)
    printf("Generating laboratories...")
    laboratories = []
    histories = []
    isolation_patients = existing_patients.where(isolation: true)
    if days_ago > 10
      patient_ids_lab = isolation_patients.pluck(:id).sample(isolation_patients.count * rand(90..95) / 100)
    else
      patient_ids_lab = isolation_patients.pluck(:id).sample(isolation_patients.count * rand(20..30) / 100)
    end
    patient_ids_lab.each_with_index do |patient_id, index|
      printf("\rGenerating laboratory #{index+1} of #{patient_ids_lab.length}...")
      lab_ts = create_fake_timestamp(today, today)
      if days_ago > 10
        result = (Array.new(12, 'positive') + ['negative', 'indeterminate', 'other']).sample
      elsif patient_id % 4 == 0
        result = ['negative', 'indeterminate', 'other'].sample
      else
        result = (Array.new(1, 'positive') + Array.new(1, 'negative') + ['indeterminate', 'other']).sample
      end
      laboratories << Laboratory.new(
        patient_id: patient_id,
        lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'].sample,
        specimen_collection: create_fake_timestamp(1.week.ago, today),
        report: create_fake_timestamp(today, today),
        result: result,
        created_at: lab_ts,
        updated_at: lab_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: User.all.select { |u| u.role?('public_health') }.sample[:email],
        comment: "User added a new lab result.",
        history_type: 'Lab Result',
        created_at: lab_ts,
        updated_at: lab_ts
      )
    end
    Laboratory.import! laboratories
    printf(" done.\n")

    return histories
  end

  def demo_populate_close_contacts(today, days_ago, existing_patients)
    printf("Generating close contacts...")
    close_contacts = []
    histories = []
    patient_ids = existing_patients.pluck(:id).sample(existing_patients.count * rand(15..25) / 100)
    enrolled_close_contacts_ids = existing_patients.where.not(id: patient_ids).pluck(:id).sample(existing_patients.count * rand(5..15) / 100)
    enrolled_close_contacts = Patient.where(id: enrolled_close_contacts_ids).pluck(:id, :first_name, :last_name, :primary_telephone, :email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating close contact #{index+1} of #{patient_ids.length}...")
      close_contact_ts = create_fake_timestamp(today, today)
      close_contact = {
        patient_id: patient_id,
        created_at: close_contact_ts,
        updated_at: close_contact_ts,
        notes: rand < 0.7 ? Faker::Hacker.say_something_smart : nil,
        contact_attempts: rand < 0.4 ? rand(1..5) : nil
      }
      if index < enrolled_close_contacts.size
        close_contact[:enrolled_id] = enrolled_close_contacts[index][0]
        close_contact[:first_name] = enrolled_close_contacts[index][1]
        close_contact[:last_name] = enrolled_close_contacts[index][2]
        close_contact[:primary_telephone] = enrolled_close_contacts[index][3]
        close_contact[:email] = enrolled_close_contacts[index][4]
      else
        close_contact[:enrolled_id] = nil
        close_contact[:first_name] = "#{rand < 0.5 ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
        close_contact[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
        close_contact[:primary_telephone] = rand < 0.85 ? "+155555501#{rand(9)}#{rand(9)}" : nil
        close_contact[:email] = rand < 0.75 ? "#{rand(1000000000..9999999999)}fake@example.com" : nil
      end
      close_contacts << close_contact
      histories << History.new(
        patient_id: patient_id,
        created_by: 'Sara Alert System',
        comment: "User created a new close contact.",
        history_type: 'Close Contact'
      )
    end
    CloseContact.import! close_contacts
    printf(" done.\n")

    return histories
  end

  def demo_populate_transfers(today, existing_patients, jurisdictions, assigned_users)
    printf("Generating transfers...")
    transfers = []
    histories = []
    patient_updates = {}
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path).map {|id, path| [id, path]}]
    patients_transfer = existing_patients.pluck(:id, :jurisdiction_id, :assigned_user).sample(existing_patients.count * rand(5..10) / 100)
    patients_transfer.each_with_index do |(patient_id, jur_id, assigned_user), index|
      printf("\rGenerating transfer #{index+1} of #{patients_transfer.length}...")
      transfer_ts = create_fake_timestamp(today, today)
      to_jurisdiction = (jurisdictions.ids - [jur_id]).sample
      patient_updates[patient_id] = {
        jurisdiction_id: to_jurisdiction,
        assigned_user: assigned_user.nil? ? nil : assigned_users[to_jurisdiction].sample
      }
      transfers << Transfer.new(
        patient_id: patient_id,
        to_jurisdiction_id: to_jurisdiction,
        from_jurisdiction_id: jur_id,
        who_id: User.all.select { |u| u.role?('public_health') }.sample[:id],
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: User.all.select { |u| u.role?('public_health') }.sample[:email],
        comment: "User changed jurisdiction from \"#{jurisdiction_paths[jur_id]}\" to #{jurisdiction_paths[to_jurisdiction]}.",
        history_type: 'Monitoring Change',
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
    end
    Patient.update(patient_updates.keys, patient_updates.values)
    Transfer.import! transfers
    printf(" done.\n")

    return histories
  end

  def demo_populate_close_contacts(today, days_ago, existing_patients)
    printf("Generating close contacts...")
    close_contacts = []
    histories = []
    patient_ids = existing_patients.pluck(:id).sample(existing_patients.count * rand(15..25) / 100)
    enrolled_close_contacts_ids = existing_patients.where.not(id: patient_ids).pluck(:id).sample(existing_patients.count * rand(5..15) / 100)
    enrolled_close_contacts = Patient.where(id: enrolled_close_contacts_ids).pluck(:id, :first_name, :last_name, :primary_telephone, :email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating close contact #{index+1} of #{patient_ids.length}...")
      close_contact_ts = create_fake_timestamp(today, today)
      close_contact = {
        patient_id: patient_id,
        created_at: close_contact_ts,
        updated_at: close_contact_ts,
        notes: rand < 0.7 ? Faker::Hacker.say_something_smart : nil,
        contact_attempts: rand < 0.4 ? rand(1..5) : nil
      }
      if index < enrolled_close_contacts.size
        close_contact[:enrolled_id] = enrolled_close_contacts[index][0]
        close_contact[:first_name] = enrolled_close_contacts[index][1]
        close_contact[:last_name] = enrolled_close_contacts[index][2]
        close_contact[:primary_telephone] = enrolled_close_contacts[index][3]
        close_contact[:email] = enrolled_close_contacts[index][4]
      else
        close_contact[:enrolled_id] = nil
        close_contact[:first_name] = "#{rand < 0.5 ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
        close_contact[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
        close_contact[:primary_telephone] = rand < 0.85 ? "+155555501#{rand(9)}#{rand(9)}" : nil
        close_contact[:email] = rand < 0.75 ? "#{rand(1000000000..9999999999)}fake@example.com" : nil
      end
      close_contacts << close_contact
      histories << History.new(
        patient_id: patient_id,
        created_by: User.all.select { |u| u.role?('public_health') }.sample[:email],
        comment: "User created a new close contact.",
        history_type: 'Close Contact',
        created_at: close_contact_ts,
        updated_at: close_contact_ts
      )
    end
    CloseContact.import! close_contacts
    printf(" done.\n")

    return histories
  end

  def demo_populate_contact_attempts(today, existing_patients)
    printf("Generating contact attempts...")
    contact_attempts = []
    histories = []
    patients_contact_attempts = existing_patients.pluck(:id).sample(existing_patients.count * rand(10..20) / 100)
    patients_contact_attempts.each_with_index do |patient_id, index|
      printf("\rGenerating contact attempt #{index+1} of #{patients_contact_attempts.length}...")
      successful = rand < 0.45
      note = rand < 0.65 ? " #{Faker::TvShows::GameOfThrones.quote}" : ''
      contact_attempt_ts = create_fake_timestamp(today, today)
      user = User.all.select { |u| u.role?('public_health') }.sample
      manual_attempt = rand < 0.7
      if manual_attempt
        contact_attempts << ContactAttempt.new(
          patient_id: patient_id,
          user_id: user[:id],
          successful: successful,
          note: note,
          created_at: contact_attempt_ts,
          updated_at: contact_attempt_ts
        )
      end
      histories << History.new(
        patient_id: patient_id,
        created_by: manual_attempt ? user[:email] : 'Sara Alert System',
        comment: "#{successful ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{note}",
        history_type: 'Contact Attempt',
        created_at: contact_attempt_ts,
        updated_at: contact_attempt_ts
      )
    end
    ContactAttempt.import! contact_attempts
    printf(" done.\n")

    return histories
  end

  def demo_populate_histories(today, histories)
    printf("Writing histories...")
    History.import! histories
    printf(" done.\n")
  end

  def demo_populate_linelists
    # populate :latest_assessment_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(created_at) AS latest_assessment_at
        FROM assessments
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_assessment_at = t.latest_assessment_at
    SQL

    # populate :latest_fever_or_fever_reducer_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT assessments.patient_id, MAX(assessments.created_at) AS latest_fever_or_fever_reducer_at
        FROM assessments
        INNER JOIN conditions ON assessments.id = conditions.assessment_id
        INNER JOIN symptoms ON conditions.id = symptoms.condition_id
        WHERE (symptoms.name = 'fever' OR symptoms.name = 'used-a-fever-reducer') AND symptoms.bool_value = true
        GROUP BY assessments.patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_fever_or_fever_reducer_at = t.latest_fever_or_fever_reducer_at
    SQL

    # populate :latest_positive_lab_at
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(specimen_collection) AS latest_positive_lab_at
        FROM laboratories
        WHERE result = 'positive'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_positive_lab_at = t.latest_positive_lab_at
    SQL

    # populate :negative_lab_count
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS negative_lab_count
        FROM laboratories
        WHERE result = 'negative'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.negative_lab_count = t.negative_lab_count
    SQL

    # populate :latest_transfer_at and :latest_transfer_from
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT transfers.patient_id, transfers.from_jurisdiction_id AS transferred_from, latest_transfers.transferred_at
        FROM transfers
        INNER JOIN (
          SELECT patient_id, MAX(created_at) AS transferred_at
          FROM transfers
          GROUP BY patient_id
        ) latest_transfers ON transfers.patient_id = latest_transfers.patient_id
          AND transfers.created_at = latest_transfers.transferred_at
      ) t ON patients.id = t.patient_id
      SET patients.latest_transfer_from = t.transferred_from, patients.latest_transfer_at = t.transferred_at
    SQL
  end

  def demo_cache_analytics(today, cache_analytics)
    printf("Caching analytics...")
    if cache_analytics || (day + 1) == days
      Rake::Task["analytics:cache_current_analytics"].reenable
      Rake::Task["analytics:cache_current_analytics"].invoke
      # Add time onto update time for more realistic reports
      t = Time.now
      date_time_update = DateTime.new(today.year, today.month, today.day, t.hour, t.min, t.sec, t.zone)
      Analytic.where('created_at > ?', 1.hour.ago).update_all(created_at: date_time_update, updated_at: date_time_update)
    end
    printf(" done.\n")
  end

  def create_fake_timestamp(from, to)
    Faker::Time.between_dates(from: from, to: to >= Date.today ? Time.now : to, period: :all)
  end
end
