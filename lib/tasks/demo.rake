# frozen_string_literal: true

# rubocop:disable Layout/LineLength
namespace :demo do
  desc 'Clear all sidekiq queues'
  task clear_sidekiq: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    puts 'Clearing sidekiq...'
    require 'sidekiq/api'
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::DeadSet.new.clear
    puts 'sidekiq cleared!'
  end

  desc 'Backup the database'
  task backup_database: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    username = ActiveRecord::Base.configurations.configurations[1].config['username']
    database = ActiveRecord::Base.configurations.configurations[1].config['database']
    system "mysqldump --opt --user=#{username} #{database} > sara_database_#{Time.now.to_i}.sql"
  end

  desc 'Restore the database'
  task restore_database: :environment do
    # Example usage: rake demo:restore_database FILE=sara_database_1606835867.sql
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
    raise 'FILE environment variable must be set to run this task' if ENV['FILE'].nil?

    username = ActiveRecord::Base.configurations.configurations[1].config['username']
    database = ActiveRecord::Base.configurations.configurations[1].config['database']
    system "mysql --user=#{username} #{database} < #{ENV['FILE']}"
  end

  # Duplicate existing monitoree data
  # Note: comment out `around_save :inform_responder, if: :responder_id_changed?` in app/models/patient.rb to speed up process
  desc 'Generate N many more monitorees based on existing data'
  task create_bulk_data: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_patients = (ENV['COUNT'] || 100_000).to_i
    num_forks = (ENV['FORKS'] || 8).to_i
    batch_size = [(num_patients / num_forks) / 10, 1].max

    pids = []
    readers = []
    outputs = []

    ::ActiveRecord::Base.clear_all_connections!
    num_forks.times do |fork_num|
      patients = Patient.where('patients.responder_id = patients.id AND patients.id % ? = ?', num_forks, fork_num)
      reader, writer = IO.pipe

      pids << fork do
        reader.close
        writer.puts '0 patients created @ 0 p/s\n'
        ::ActiveRecord::Base.establish_connection

        num_to_create = (num_patients / num_forks) + (fork_num < num_patients % num_forks ? 1 : 0)
        num_created = 0
        start_time = Time.now

        while num_created < num_to_create
          # deep_duplicate returns an array with of old and new patient ids (including duplicated dependents)
          num_created += deep_duplicate_patients(patients.offset(rand(patients.size)).limit(batch_size), [], num_to_create).size

          # Send output to parent process
          writer.puts "#{num_created} patients created @ #{(num_created / (Time.now - start_time)).truncate(2)} p/s\n"
        end
      ensure
        ::ActiveRecord::Base.clear_all_connections!
        writer.close
        Process.exit! true
      end

      readers << reader
      writer.close
    end

    # Update outputs from child processes
    Thread.new do
      loop do
        readers.each_with_index do |reader, index|
          output = reader.gets
          outputs[index] = output unless output.blank?
        end
      end
    end

    # Print combined output
    puts ''
    start_time = Time.now
    loop do
      num_created = 0
      num_forks.times do |index|
        puts "Fork #{index + 1} (pid = #{pids[index]}): #{outputs[index]}"
        num_created += outputs[index]&.split&.first&.to_i || 0
      end
      print "\nTotal: #{num_created} patients created @ #{(num_created / (Time.now - start_time)).truncate(2)} p/s\n\n"
      sleep 0.1

      puts "\r" + ("\e[A\e[K" * (num_forks + 4)) if num_created < num_patients
      break unless num_created < num_patients
    end

    puts 'Done!'
  end

  desc 'Configure the database for demo use'
  task setup: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    #####################################

    print 'Gathering jurisdictions...'

    jurisdictions = {}

    jurisdictions[:usa] = Jurisdiction.where(name: 'USA').first
    jurisdictions[:state_1] = Jurisdiction.where(name: 'State 1').first
    jurisdictions[:state_2] = Jurisdiction.where(name: 'State 2').first
    jurisdictions[:county_1] = Jurisdiction.where(name: 'County 1').first
    jurisdictions[:county_2] = Jurisdiction.where(name: 'County 2').first
    jurisdictions[:county_3] = Jurisdiction.where(name: 'County 3').first
    jurisdictions[:county_4] = Jurisdiction.where(name: 'County 4').first

    if jurisdictions.value?(nil)
      puts ' Demonstration jurisdictions were not found! Make sure to run `bundle exec rake admin:import_or_update_jurisdictions` with the demonstration jurisdictions.yml'
      exit(1)
    end

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    User.create(email: 'state1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS1C1_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county_1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS1C2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county_2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state2_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:state_2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS2C3_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county_3], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS2C4_enroller@example.com', password: '1234567ab!', role: Roles::ENROLLER, jurisdiction: jurisdictions[:county_4], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    User.create(email: 'state1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS1C1_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county_1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS1C2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county_2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state2_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:state_2], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS2C3_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county_3], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS2C4_epi@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH, jurisdiction: jurisdictions[:county_4], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    User.create(email: 'epi_enroller_all@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state1_epi_enroller@example.com', password: '1234567ab!', role: Roles::PUBLIC_HEALTH_ENROLLER, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    User.create(email: 'admin1@example.com', password: '1234567ab!', role: Roles::ADMIN, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    User.create(email: 'analyst_all@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'localS1C1_analyst@example.com', password: '1234567ab!', role: Roles::ANALYST, jurisdiction: jurisdictions[:county_1], force_password_change: false, authy_enabled: false, authy_enforced: false, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating super users...'

    User.create(email: 'usa_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state1_super_user@example.com', password: '1234567ab!', role: Roles::SUPER_USER, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating contract tracer users...'

    User.create(email: 'usa_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:usa], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)
    User.create(email: 'state1_contact_tracer@example.com', password: '1234567ab!', role: Roles::CONTACT_TRACER, jurisdiction: jurisdictions[:state_1], force_password_change: false, authy_enabled: false, authy_enforced: false, api_enabled: true, notes: Faker::GreekPhilosophers.quote)

    puts ' done!'

    #####################################

    print 'Creating demo Doorkeeper OAuth application...'

    OauthApplication.create(name: 'demo', redirect_uri: 'http://localhost:3000/redirect', scopes: 'user/Patient.* user/Observation.read user/QuestionnaireResponse.read', uid: 'demo-oauth-app-uid', secret: 'demo-oauth-app-secret')

    puts ' done!'

    #####################################

    puts ''
  end

  desc 'Add synthetic patient/monitoree data to the database for an initial time period in days'
  task populate: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    # Remove analytics that are created in admin:import_or_update_jurisdictions task
    Analytic.delete_all

    patient_limit = (ENV['LIMIT'] || 1_500_000).to_i
    days = (ENV['DAYS'] || 14).to_i
    num_patients_today = (ENV['COUNT'] || 25).to_i
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all

    # Create different set of assigned users for each jurisdiction with relatively low variance to mimic data distribution in the context of SaraAlert
    assigned_users = (jurisdictions.pluck(:id).map { |id| [id, 10.times.map { rand(1..100_000) }] }).to_h
    case_ids = (jurisdictions.pluck(:id).map { |id| [id, 15.times.map { Faker::Number.leading_zero_number(digits: 8) }] }).to_h

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))
    available_lang_codes = Languages.all_languages.keys.to_a.map(&:to_s)

    # Freeze beginning of day outside loop to prevent problems when script is called over midnight
    beginning_of_today = DateTime.now.beginning_of_day
    created_patients = 0

    # Get symptoms for each jurisdiction
    threshold_conditions = fetch_all_threshold_conditions

    enroller_users = User.where(role: 'enroller').pluck(:id, :email)
    public_health_users = User.where(role: 'public_health').pluck(:id, :email)

    days.times do |day|
      if created_patients > patient_limit
        puts "Patient limit of #{patient_limit} has been reached!"
        break
      end

      # Calculate number of days ago
      days_ago = days - day
      beginning_of_day = beginning_of_today - days_ago.days

      # Create the patients for this day
      printf("Simulating day #{day + 1} (#{beginning_of_day.to_date}):\n")

      # Populate patients, assessments, laboratories, transfers, histories, analytics
      demo_populate_day(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions, enroller_users, public_health_users)
      created_patients += num_patients_today

      # Cases increase 10-20% every day
      num_patients_today += (num_patients_today * (0.1 + (rand / 10))).round
      # Protect from going over the patient limit
      num_patients_today = patient_limit - created_patients if created_patients + num_patients_today > patient_limit

      puts ''
    end
  end

  desc 'Add synthetic patient/monitoree data to the database for a single day (today)'
  task update: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development' || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_patients_today = (ENV['COUNT'] || 25).to_i * 20
    cache_analytics = (ENV['SKIP_ANALYTICS'] != 'true')

    jurisdictions = Jurisdiction.all
    assigned_users = (jurisdictions.map { |jur| [jur[:id], jur.assigned_users] }).to_h
    case_ids = (jurisdictions.map { |jur| [jur[:id], jur.immediate_patients.where.not(contact_of_known_case_id: nil).distinct.pluck(:contact_of_known_case_id).sort] }).to_h

    counties = YAML.safe_load(File.read(Rails.root.join('lib', 'assets', 'counties.yml')))
    available_lang_codes = Languages.all_languages.keys.to_a.map(&:to_s)

    puts 'Simulating today'

    # Get symptoms for each jurisdiction
    # Used in demo_populate_assessments
    threshold_conditions = fetch_all_threshold_conditions

    enroller_users = User.where(role: 'enroller').pluck(:id, :email)
    public_health_users = User.where(role: 'public_health').pluck(:id, :email)

    demo_populate_day(DateTime.now.beginning_of_day, num_patients_today, 0, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions, enroller_users, public_health_users)
  end

  def fetch_all_threshold_conditions
    print 'Fetching threshold_conditions for all jurisdictions... '
    threshold_conditions = {}
    Jurisdiction.all.each do |jurisdiction|
      threshold_condition = jurisdiction.hierarchical_condition_unpopulated_symptoms
      threshold_conditions[jurisdiction[:id]] = {
        hash: threshold_condition[:threshold_condition_hash],
        symptoms: threshold_condition.symptoms
      }
    end
    puts 'done.'
    threshold_conditions
  end

  def demo_populate_day(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, cache_analytics, counties, available_lang_codes, threshold_conditions, enroller_users, public_health_users)
    # Transactions speeds things up a bit
    ActiveRecord::Base.transaction do
      # Patients created before today
      existing_patients = Patient.monitoring_open.where('created_at < ?', beginning_of_day)

      # Create patients
      demo_populate_patients(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, counties, available_lang_codes, enroller_users, public_health_users)

      # Create assessments
      demo_populate_assessments(beginning_of_day, days_ago, existing_patients, threshold_conditions, public_health_users)

      # Create laboratories
      demo_populate_laboratories(beginning_of_day, days_ago, existing_patients, public_health_users)

      # Create vaccinations
      demo_populate_vaccines(beginning_of_day, existing_patients, public_health_users)

      # Create transfers
      demo_populate_transfers(beginning_of_day, existing_patients, jurisdictions, assigned_users, public_health_users)

      # Create close contacts
      demo_populate_close_contacts(beginning_of_day, existing_patients, public_health_users)

      # Create contact attempts
      demo_populate_contact_attempts(beginning_of_day, existing_patients, public_health_users)
    end

    # Update linelist fields (separate transaction)
    demo_populate_linelists

    # Cache analytics
    demo_cache_analytics(beginning_of_day) if cache_analytics
  end

  def demo_populate_patients(beginning_of_day, num_patients_today, days_ago, jurisdictions, assigned_users, case_ids, counties, available_lang_codes, enroller_users, public_health_users)
    include PatientHelper

    territory_names = ['American Samoa', 'District of Columbia', 'Federated States of Micronesia', 'Guam', 'Marshall Islands', 'Northern Mariana Islands',
                       'Palau', 'Puerto Rico', 'Virgin Islands'].freeze

    rand_enroller = enroller_users.sample
    printf('Generating monitorees...')
    patients = []
    histories = []
    num_patients_today.times do |i|
      printf("\rGenerating monitoree #{i + 1} of #{num_patients_today}...") unless ENV['APP_IN_CI']
      patient = Patient.new

      # Identification
      sex = Faker::Gender.binary_type
      patient[:sex] = rand < 0.9 ? sex : 'Unknown' if rand < 0.9
      patient[:gender_identity] = ValidationHelper::VALID_PATIENT_ENUMS[:gender_identity].sample if rand < 0.7
      patient[:sexual_orientation] = ValidationHelper::VALID_PATIENT_ENUMS[:sexual_orientation].sample if rand < 0.6
      patient[:first_name] = "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}"
      patient[:middle_name] = "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:last_name] = "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}"
      patient[:date_of_birth] = Faker::Date.birthday(min_age: 1, max_age: 85)
      patient[:age] = ((Date.today - patient[:date_of_birth]) / 365.25).round
      if rand < 0.9
        exclusive = rand < 0.75
        ValidationHelper::RACE_OPTIONS[exclusive ? :exclusive : :non_exclusive].map { |option| option[:race] }
                                                                               .sample(exclusive ? 1 : rand(0..4))
                                                                               .each { |race| patient[race] = true }
      end
      patient[:ethnicity] = rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino'
      patient[:primary_language] = rand < 0.7 ? 'eng' : available_lang_codes.sample
      patient[:secondary_language] = available_lang_codes.sample if rand < 0.4
      patient[:interpretation_required] = rand < 0.15
      patient[:nationality] = Faker::Nation.nationality if rand < 0.6
      patient[:user_defined_id_statelocal] = "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}" if rand < 0.7
      patient[:user_defined_id_cdc] = Faker::Code.npi if rand < 0.2
      patient[:user_defined_id_nndss] = Faker::Code.rut if rand < 0.2

      # Contact Information
      patient[:preferred_contact_method] = ValidationHelper::VALID_PATIENT_ENUMS[:preferred_contact_method].sample
      if ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include?(patient[:preferred_contact_method]) && rand < 0.8
        patient[:preferred_contact_time] = rand < 0.6 ? ['Morning', 'Afternoon', 'Evening', ''].sample : rand(0..23)
      end
      patient[:primary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:preferred_contact_method] != 'E-mailed Web Link' || rand < 0.5
      patient[:primary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:primary_telephone_type].sample if patient[:primary_telephone]
      patient[:secondary_telephone] = "+155555501#{rand(9)}#{rand(9)}" if patient[:primary_telephone] && rand < 0.5
      patient[:secondary_telephone_type] = ValidationHelper::VALID_PATIENT_ENUMS[:secondary_telephone_type].sample if patient[:secondary_telephone]
      patient[:email] = "#{rand(1_000_000_000..9_999_999_999)}fake@example.com" if patient[:preferred_contact_method] == 'E-mailed Web Link' || rand < 0.5

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
        patient[:date_of_departure] = beginning_of_day - (rand < 0.3 ? 1.day : 0.days)
        patient[:source_of_report] = ValidationHelper::VALID_PATIENT_ENUMS[:source_of_report].sample if rand < 0.7
        patient[:source_of_report_specify] = Faker::TvShows::SiliconValley.invention if patient[:source_of_report] == 'Other'
        patient[:flight_or_vessel_number] = "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}"
        patient[:flight_or_vessel_carrier] = "#{Faker::Name.first_name} Airlines"
        patient[:port_of_entry_into_usa] = Faker::Address.city
        patient[:date_of_arrival] = beginning_of_day
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
        patient[:additional_planned_travel_start_date] = beginning_of_day + rand(6).days
        patient[:additional_planned_travel_end_date] = patient[:additional_planned_travel_start_date] + rand(10).days
        patient[:additional_planned_travel_related_notes] = Faker::ChuckNorris.fact if rand < 0.4
      end

      # Potential Exposure Info
      patient[:isolation] = rand < (days_ago > 10 ? 0.9 : 0.4)
      if patient[:isolation]
        if rand < 0.7
          patient[:symptom_onset] = beginning_of_day - rand(10).days
          patient[:user_defined_symptom_onset] = true
        end
      else
        patient[:continuous_exposure] = rand < 0.3
        patient[:last_date_of_exposure] = beginning_of_day - rand(5).days unless patient[:continuous_exposure]
      end
      patient[:potential_exposure_location] = Faker::Address.city if rand < 0.7
      patient[:potential_exposure_country] = Faker::Address.country if rand < 0.8
      patient[:exposure_notes] = Faker::Games::LeagueOfLegends.quote if rand < 0.5
      patient[:jurisdiction_id] = jurisdictions.sample[:id]
      patient[:assigned_user] = assigned_users[patient[:jurisdiction_id]].sample if rand < 0.8
      patient[:exposure_risk_assessment] = ValidationHelper::VALID_PATIENT_ENUMS[:exposure_risk_assessment].sample
      patient[:monitoring_plan] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_plan].sample
      if rand < 0.85
        patient[:contact_of_known_case] = rand < 0.5
        patient[:contact_of_known_case_id] = case_ids[patient[:jurisdiction_id]].sample(rand(1..3)).join(', ') if patient[:contact_of_known_case] && rand < 0.9
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

      # Other fields populated upon enrollment
      patient[:submission_token] = SecureRandom.urlsafe_base64[0, 10]
      patient[:time_zone] = time_zone_for_state(patient[:monitored_address_state] || patient[:address_state] || 'massachusetts')
      patient[:creator_id] = rand_enroller[0]
      patient[:responder_id] = 1 # temporarily set responder_id to 1 to pass schema validation
      patient_ts = create_fake_timestamp(beginning_of_day)
      patient[:created_at] = patient_ts
      patient[:updated_at] = patient_ts

      # Update monitoring status
      patient[:extended_isolation] = beginning_of_day + rand(10).days if patient[:isolation] && rand < 0.3
      patient[:case_status] = patient[:isolation] ? %w[Confirmed Probable].sample : ['Suspect', 'Unknown', 'Not a Case', nil].sample
      patient[:monitoring] = rand < 0.95
      patient[:closed_at] = patient[:updated_at] unless patient[:monitoring]
      patient[:monitoring_reason] = ValidationHelper::VALID_PATIENT_ENUMS[:monitoring_reason].sample if patient[:monitoring].nil?
      patient[:public_health_action] = patient[:isolation] || rand < 0.8 ? 'None' : ValidationHelper::VALID_PATIENT_ENUMS[:public_health_action].sample
      patient[:pause_notifications] = rand < 0.1
      patient[:last_assessment_reminder_sent] = beginning_of_day - rand(7).days if rand < 0.3

      # Follow-up Flag
      if rand < 0.15
        patient[:follow_up_reason] = ValidationHelper::FOLLOW_UP_FLAG_REASONS.sample
        patient[:follow_up_note] = Faker::GreekPhilosophers.quote if rand < 0.75
      end

      patients << patient
    end
    print ' importing monitorees...'
    Patient.import! patients
    new_patients = Patient.where('created_at >= ?', beginning_of_day)
    new_patients.update_all('responder_id = id')

    # Create household members (10-20% of patients are managed by a HoH)
    print ' setting dependents...'
    new_dependents = new_patients.limit(new_patients.count * rand(10..20) / 100).order('RAND()')
    new_hohs = new_patients - new_dependents
    new_dependents_updates =  new_dependents.map do
      hoh = new_hohs.sample
      { responder_id: hoh[:id], jurisdiction_id: hoh[:jurisdiction_id] }
    end
    Patient.update(new_dependents.map { |p| p[:id] }, new_dependents_updates)

    # Create first positive lab for patients who are asymptomatic
    laboratories = []
    asymptomatic_cases = new_patients.where(isolation: true, symptom_onset: nil)
    user_emails = User.where(id: asymptomatic_cases.distinct.pluck(:creator_id)).pluck(:id, :email).to_h
    asymptomatic_cases.each do |patient|
      laboratories << Laboratory.new(
        patient_id: patient[:id],
        lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'].sample,
        specimen_collection: create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day),
        report: create_fake_timestamp(beginning_of_day),
        result: 'positive',
        created_at: patient[:created_at],
        updated_at: patient[:created_at]
      )
      histories << History.new(
        patient_id: patient[:id],
        created_by: user_emails[patient[:creator_id]],
        comment: 'User added a new lab result.',
        history_type: 'Lab Result',
        created_at: patient[:created_at],
        updated_at: patient[:created_at]
      )
    end
    Laboratory.import! laboratories

    puts "\n" unless ENV['APP_IN_CI']
    new_patients.each_with_index do |patient, i|
      printf("\rGenerating histories for monitoree #{i + 1} of #{new_patients.size}...") unless ENV['APP_IN_CI']
      # enrollment
      histories << History.new(
        patient_id: patient[:id],
        created_by: rand_enroller[1],
        comment: 'User enrolled monitoree.',
        history_type: 'Enrollment',
        created_at: patient[:created_at],
        updated_at: patient[:created_at]
      )
      # monitoring status
      unless patient[:monitoring]
        histories << History.new(
          patient_id: patient[:id],
          created_by: rand_enroller[1],
          comment: "User changed monitoring status to \"Not Monitoring\". Reason: #{patient[:monitoring_reason]}",
          history_type: 'Monitoring Change',
          created_at: patient[:updated_at],
          updated_at: patient[:updated_at]
        )
      end
      # exposure risk assessment
      if patient[:exposure_risk_assessment].present?
        histories << History.new(
          created_by: rand_enroller[1],
          comment: "User changed exposure risk assessment to \"#{patient[:exposure_risk_assessment]}\".",
          patient_id: patient[:id],
          history_type: 'Monitoring Change',
          created_at: patient[:updated_at],
          updated_at: patient[:updated_at]
        )
      end
      # case status
      if patient[:case_status].present?
        histories << History.new(
          patient_id: patient[:id],
          created_by: rand_enroller[1],
          comment: "User changed case status to \"#{patient[:case_status]}\", and chose to \"Continue Monitoring in Isolation Workflow\".",
          history_type: 'Monitoring Change',
          created_at: patient[:updated_at],
          updated_at: patient[:updated_at]
        )
      end
      # public health action
      unless patient[:public_health_action] == 'None'
        histories << History.new(
          patient_id: patient[:id],
          created_by: rand_enroller[1],
          comment: "User changed latest public health action to \"#{patient[:public_health_action]}\".",
          history_type: 'Monitoring Change',
          created_at: patient[:updated_at],
          updated_at: patient[:updated_at]
        )
      end
      # pause notifications
      next unless patient[:pause_notifications]

      histories << History.new(
        patient_id: patient[:id],
        created_by: rand_enroller[1],
        comment: 'User paused notifications for this monitoree.',
        history_type: 'Monitoring Change',
        created_at: patient[:updated_at],
        updated_at: patient[:updated_at]
      )
    end
    History.import! histories

    puts 'done!'
  end

  def demo_populate_assessments(beginning_of_day, days_ago, existing_patients, threshold_conditions, public_health_users)
    printf('Generating assessments...')
    assessments = []
    assessment_receipts = []
    histories = []
    patient_ids_and_sub_tokens = existing_patients.limit(existing_patients.count * rand(55..60) / 100).order('RAND()').pluck(:id, :submission_token)
    patient_ids_and_sub_tokens.each_with_index do |(patient_id, sub_token), index|
      printf("\rGenerating assessment #{index + 1} of #{patient_ids_and_sub_tokens.length}...") unless ENV['APP_IN_CI']
      assessment_ts = create_fake_timestamp(beginning_of_day)
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
        comment: 'Sara Alert sent a report reminder to this monitoree via Telephone call.',
        history_type: History::HISTORY_TYPES[:report_reminder],
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_users.sample[1],
        comment: 'User created a new report.',
        history_type: 'Report Created',
        created_at: assessment_ts,
        updated_at: assessment_ts
      )
    end

    # Create assessment receipts and replace any existing ones
    AssessmentReceipt.where(submission_token: assessment_receipts.map { |assessment_receipt| assessment_receipt[:submission_token] }).destroy_all
    AssessmentReceipt.import! assessment_receipts
    Assessment.import! assessments
    puts 'done!'

    printf('Generating condition for assessments...')
    reported_conditions = []
    new_assessments = Assessment.where('assessments.created_at >= ?', beginning_of_day).joins(:patient)
    new_assessments.each_with_index do |assessment, index|
      printf("\rGenerating condition for assessment #{index + 1} of #{new_assessments.length}...") unless ENV['APP_IN_CI']
      reported_conditions << ReportedCondition.new(
        assessment_id: assessment[:id],
        threshold_condition_hash: threshold_conditions[assessment.patient.jurisdiction_id][:hash],
        created_at: assessment[:created_at],
        updated_at: assessment[:updated_at]
      )
    end
    ReportedCondition.import! reported_conditions
    puts 'done!'

    # Create earlier symptom onset dates to meet isolation symptomatic non test based requirement
    symptomatic_assessments = new_assessments.where('patients.symptom_onset IS NOT NULL')
                                             .or(
                                               new_assessments.where('patients.isolation = ?', false)
                                             )
                                             .where('patient_id % 4 <> 0')
                                             .limit(new_assessments.count * (days_ago > 10 ? rand(75..80) : rand(20..25)) / 100)
                                             .order('RAND()')

    printf('Generating symptoms for assessments...')
    symptoms = []
    new_reported_conditions = ReportedCondition.where('conditions.created_at >= ?', beginning_of_day).joins(assessment: :reported_condition)
    new_reported_conditions.each_with_index do |reported_condition, index|
      printf("\rGenerating symptoms for assessment #{index + 1} of #{new_reported_conditions.length}...") unless ENV['APP_IN_CI']
      threshold_symptoms = threshold_conditions[reported_condition.assessment.patient.jurisdiction_id][:symptoms]
      symptomatic_assessment = symptomatic_assessments.include?(reported_condition.assessment)
      num_symptomatic_symptoms = ((rand**2) * threshold_symptoms.length).floor # creates a distribution favored towards fewer symptoms
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
          int_value: threshold_symptom[:type] == 'IntSymptom' ? ((threshold_symptom.value || 0) + rand(10) * (symptomatic_symptom ? -1 : 1)) : nil,
          created_at: reported_condition[:created_at],
          updated_at: reported_condition[:updated_at]
        )
      end
    end
    Symptom.import! symptoms
    puts 'done!'

    printf('Updating symptomatic statuses...')
    assessment_symptomatic_statuses = {}
    patient_symptom_onset_date_updates = {}
    symptomatic_assessments.each_with_index do |assessment, index|
      printf("\rUpdating symptomatic status #{index + 1} of #{symptomatic_assessments.length}...") unless ENV['APP_IN_CI']
      if assessment.symptomatic?
        assessment_symptomatic_statuses[assessment[:id]] = { symptomatic: true }
        patient_symptom_onset_date_updates[assessment[:patient_id]] = { symptom_onset: assessment[:created_at] }
      end
    end
    Assessment.update(assessment_symptomatic_statuses.keys, assessment_symptomatic_statuses.values)
    Patient.update(patient_symptom_onset_date_updates.keys, patient_symptom_onset_date_updates.values)
    History.import! histories

    puts 'done!'
  end

  def demo_populate_laboratories(beginning_of_day, days_ago, existing_patients, public_health_users)
    printf('Generating laboratories...')
    laboratories = []
    histories = []
    isolation_patients = existing_patients.where(isolation: true)
    patient_ids_lab = if days_ago > 10
                        isolation_patients.limit(isolation_patients.count * rand(90..95) / 100).order('RAND()').pluck(:id)
                      else
                        isolation_patients.limit(isolation_patients.count * rand(20..30) / 100).order('RAND()').pluck(:id)
                      end
    patient_ids_lab.each_with_index do |patient_id, index|
      printf("\rGenerating laboratory #{index + 1} of #{patient_ids_lab.length}...") unless ENV['APP_IN_CI']
      lab_ts = create_fake_timestamp(beginning_of_day)
      result = if days_ago > 10
                 (Array.new(12, 'positive') + %w[negative indeterminate other]).sample
               elsif (patient_id % 4).zero?
                 %w[negative indeterminate other].sample
               else
                 (Array.new(1, 'positive') + Array.new(1, 'negative') + %w[indeterminate other]).sample
               end
      laboratory = Laboratory.new(
        patient_id: patient_id,
        lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other', ''].sample,
        created_at: lab_ts,
        updated_at: lab_ts
      )
      laboratory[:specimen_collection] = create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day) if rand < 0.95
      laboratory[:report] = create_fake_timestamp(beginning_of_day) if rand < 0.95
      laboratory[:result] = result if rand < 0.95
      laboratories << laboratory
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_users.sample[1],
        comment: 'User added a new lab result.',
        history_type: 'Lab Result',
        created_at: lab_ts,
        updated_at: lab_ts
      )
    end
    Laboratory.import! laboratories
    History.import! histories

    puts 'done!'
  end

  def demo_populate_vaccines(beginning_of_day, existing_patients, public_health_users)
    printf('Generating vaccinations...')
    vaccines = []
    histories = []
    patient_ids = existing_patients.limit(existing_patients.count * rand(15..25) / 100).order('RAND()').pluck(:id)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating vaccine #{index + 1} of #{patient_ids.length}...")
      vaccine_ts = create_fake_timestamp(beginning_of_day)
      group_name = Vaccine.group_name_options.sample
      notes = rand < 0.5 ? Faker::Games::LeagueOfLegends.quote : nil
      vaccines << Vaccine.new(
        patient_id: patient_id,
        group_name: group_name,
        product_name: Vaccine.product_name_options(group_name).sample,
        administration_date: create_fake_timestamp(beginning_of_day - 1.week, beginning_of_day + 1.day),
        dose_number: Vaccine::DOSE_OPTIONS.sample,
        notes: notes,
        created_at: vaccine_ts,
        updated_at: vaccine_ts
      )

      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_users.sample[1],
        comment: 'User added a new vaccine.',
        history_type: History::HISTORY_TYPES[:vaccination],
        created_at: vaccine_ts,
        updated_at: vaccine_ts
      )
    end
    Vaccine.import! vaccines
    History.import! histories

    puts 'done!'
  end

  def demo_populate_transfers(beginning_of_day, existing_patients, jurisdictions, assigned_users, public_health_users)
    printf('Generating transfers...')
    transfers = []
    histories = []
    patient_updates = {}
    jurisdiction_paths = jurisdictions.pluck(:id, :path).to_h
    patients_transfer = existing_patients.limit(existing_patients.count * rand(5..10) / 100).order('RAND()').pluck(:id, :jurisdiction_id, :assigned_user)
    patients_transfer.each_with_index do |(patient_id, jur_id, assigned_user), index|
      printf("\rGenerating transfer #{index + 1} of #{patients_transfer.length}...") unless ENV['APP_IN_CI']
      transfer_ts = create_fake_timestamp(beginning_of_day)
      to_jurisdiction = (jurisdictions.ids - [jur_id]).sample
      patient_updates[patient_id] = {
        jurisdiction_id: to_jurisdiction,
        assigned_user: assigned_user.nil? ? nil : assigned_users[to_jurisdiction].sample
      }
      transfers << Transfer.new(
        patient_id: patient_id,
        to_jurisdiction_id: to_jurisdiction,
        from_jurisdiction_id: jur_id,
        who_id: public_health_users.sample[0],
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_users.sample[1],
        comment: "User changed jurisdiction from \"#{jurisdiction_paths[jur_id]}\" to #{jurisdiction_paths[to_jurisdiction]}.",
        history_type: 'Monitoring Change',
        created_at: transfer_ts,
        updated_at: transfer_ts
      )
    end
    Patient.update(patient_updates.keys, patient_updates.values)
    Transfer.import! transfers
    History.import! histories

    puts 'done!'
  end

  def demo_populate_close_contacts(beginning_of_day, existing_patients, public_health_users)
    printf('Generating close contacts...')
    close_contacts = []
    histories = []
    patient_ids = existing_patients.limit(existing_patients.count * rand(15..25) / 100).order('RAND()').pluck(:id)
    enrolled_close_contacts_ids = existing_patients.where.not(id: patient_ids).limit(existing_patients.count * rand(5..15) / 100).order('RAND()').pluck(:id)
    enrolled_close_contacts = Patient.where(id: enrolled_close_contacts_ids).pluck(:id, :first_name, :last_name, :primary_telephone, :email)
    patient_ids.each_with_index do |patient_id, index|
      printf("\rGenerating close contact #{index + 1} of #{patient_ids.length}...") unless ENV['APP_IN_CI']
      close_contact_ts = create_fake_timestamp(beginning_of_day)
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
        close_contact[:email] = rand < 0.75 ? "#{rand(1_000_000_000..9_999_999_999)}fake@example.com" : nil
      end
      close_contacts << close_contact
      histories << History.new(
        patient_id: patient_id,
        created_by: public_health_users.sample[1],
        comment: 'User created a new close contact.',
        history_type: 'Close Contact',
        created_at: close_contact_ts,
        updated_at: close_contact_ts
      )
    end
    CloseContact.import! close_contacts
    History.import! histories

    puts 'done!'
  end

  def demo_populate_contact_attempts(beginning_of_day, existing_patients, public_health_users)
    printf('Generating contact attempts...')
    contact_attempts = []
    histories = []
    patients_contact_attempts = existing_patients.limit(existing_patients.count * rand(10..20) / 100).order('RAND()').pluck(:id)
    patients_contact_attempts.each_with_index do |patient_id, index|
      printf("\rGenerating contact attempt #{index + 1} of #{patients_contact_attempts.length}...") unless ENV['APP_IN_CI']
      successful = rand < 0.45
      note = rand < 0.65 ? " #{Faker::TvShows::GameOfThrones.quote}" : ''
      contact_attempt_ts = create_fake_timestamp(beginning_of_day)
      manual_attempt = rand < 0.7
      user = public_health_users.sample
      if manual_attempt
        contact_attempts << ContactAttempt.new(
          patient_id: patient_id,
          user_id: user[0],
          successful: successful,
          note: note,
          created_at: contact_attempt_ts,
          updated_at: contact_attempt_ts
        )
      end
      histories << History.new(
        patient_id: patient_id,
        created_by: manual_attempt ? user[1] : 'Sara Alert System',
        comment: "#{successful ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{note}",
        history_type: 'Contact Attempt',
        created_at: contact_attempt_ts,
        updated_at: contact_attempt_ts
      )
    end
    ContactAttempt.import! contact_attempts
    History.import! histories

    puts 'done!'
  end

  def demo_populate_linelists
    ActiveRecord::Base.transaction do
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

      # populate :latest_assessment_symptomatic (reset to FALSE before setting values to TRUE)
      ActiveRecord::Base.connection.execute <<-SQL.squish
        UPDATE patients
        SET patients.latest_assessment_symptomatic = FALSE
        WHERE id > 0 -- this is a workaround to ignore the safe update mode
      SQL

      ActiveRecord::Base.connection.execute <<-SQL.squish
        UPDATE patients
        JOIN (
          SELECT assessments.patient_id
          FROM assessments
          JOIN (
            SELECT patient_id, MAX(created_at) AS latest_assessment_at
            FROM assessments
            GROUP BY patient_id
          ) latest_assessments
          ON assessments.patient_id = latest_assessments.patient_id
          AND assessments.created_at = latest_assessments.latest_assessment_at
          WHERE assessments.symptomatic = TRUE
        ) latest_symptomatic_assessments
        ON patients.id = latest_symptomatic_assessments.patient_id
        SET patients.latest_assessment_symptomatic = TRUE
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

      # populate :first_positive_lab_at
      ActiveRecord::Base.connection.execute <<-SQL.squish
        UPDATE patients
        INNER JOIN (
          SELECT patient_id, MIN(specimen_collection) AS first_positive_lab_at
          FROM laboratories
          WHERE result = 'positive'
          GROUP BY patient_id
        ) t ON patients.id = t.patient_id
        SET patients.first_positive_lab_at = t.first_positive_lab_at
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
  end

  def demo_cache_analytics(beginning_of_day)
    printf('Caching analytics...')
    Rake::Task['analytics:cache_current_analytics'].reenable
    Rake::Task['analytics:cache_current_analytics'].invoke
    # Add time onto update time for more realistic reports
    Analytic.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeCount.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeSnapshot.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    MonitoreeMap.where('created_at > ?', 1.hour.ago).update_all(created_at: beginning_of_day, updated_at: beginning_of_day)
    puts 'done!'
  end

  def create_fake_timestamp(from, to = from + 1.day)
    Faker::Time.between(from: from, to: to > Time.now ? Time.now : to)
  end

  # Duplicate patient and all nested relations and change last name
  def deep_duplicate_patients(patients, old_and_new_patient_ids, num_to_create, responder: nil)
    patients.each do |patient|
      break if old_and_new_patient_ids.size >= num_to_create

      new_patient = duplicate_resource(patient)
      new_patient.responder = responder || new_patient
      new_patient.submission_token = new_patient.new_submission_token
      new_patient.save(validate: false)

      old_and_new_patient_ids << [patient.id, new_patient.id]
      old_and_new_patient_ids = deep_duplicate_patients(patient.dependents_exclude_self, old_and_new_patient_ids, num_to_create, responder: patient)
    end

    duplicate_nested_relations(*old_and_new_patient_ids.transpose) if responder.nil?

    old_and_new_patient_ids
  end

  def duplicate_nested_relations(old_patient_ids, new_patient_ids)
    # Duplicate directly nested relations
    [Assessment, Laboratory, Vaccine, CloseContact, ContactAttempt, Transfer, History].each do |collection|
      old_records = collection.where(patient_id: old_patient_ids).order(:id).to_a
      new_records = old_records.map do |resource|
        duplicate_resource(resource, foreign_keys: { patient_id: new_patient_ids[old_patient_ids.index(resource.patient_id)] })
      end
      collection.import! new_records
    end

    # Duplicate reported conditions
    old_assessment_ids = Assessment.where(patient_id: old_patient_ids).order(:id).pluck(:id)
    new_assessment_ids = Assessment.where(patient_id: new_patient_ids).order(:id).pluck(:id)
    old_conditions = ReportedCondition.where(assessment_id: old_assessment_ids).to_a
    new_conditions = old_conditions.map do |condition|
      duplicate_resource(condition, foreign_keys: { assessment_id: new_assessment_ids[old_assessment_ids.index(condition.assessment_id)] })
    end
    ReportedCondition.import! new_conditions

    # Duplicate symptoms
    old_condition_ids = old_conditions.map(&:id)
    new_condition_ids = ReportedCondition.where(assessment_id: new_assessment_ids).order(:id).pluck(:id)
    new_symptoms = Symptom.where(condition_id: old_condition_ids).map do |symptom|
      duplicate_resource(symptom, foreign_keys: { condition_id: new_condition_ids[old_condition_ids.index(symptom.condition_id)] })
    end
    Symptom.import! new_symptoms
  end

  def duplicate_resource(resource, foreign_keys: {})
    new_resource = resource.dup
    new_resource.created_at = resource.created_at
    new_resource.updated_at = resource.updated_at
    foreign_keys.each { |fk, val| new_resource[fk] = val }
    new_resource
  end
end
# rubocop:enable Layout/LineLength
