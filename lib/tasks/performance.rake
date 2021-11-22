# frozen_string_literal: true

namespace :perf do
  ##
  # PATIENT_COUNT=500000 bundle exec rails perf:trim
  #
  # This task is meant to take a database that contains more patients than intended
  # and trim it down to a specifiec number of patients using the PATIENT_COUNT env variable.
  #
  # ENV:
  #  PATIENT_COUNT (integer) The max number of patients that should be in the database.
  #
  desc 'Trim database down to a specific number of patients'
  task trim: :environment do
    unless Rails.env.development? || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
      puts 'bundle exec rails perf:populate'
      raise 'This task is only for use in a development environment'
    end

    if ENV['PATIENT_COUNT'].nil? || ENV['PATIENT_COUNT'].to_i <= 0
      puts "\nMust provide PATIENT_COUNT environment variable to indicate how many patients should be in the DB"
      puts 'export PATIENT_COUNT=500000'
      exit 1
    end

    desired_patient_count = ENV['PATIENT_COUNT'].to_i
    current_patient_count = Patient.count

    puts "Currently at #{current_patient_count} patients"
    puts "Script will delete patients until it reaches #{desired_patient_count}\n"

    Patient.uncached do
      patients = Patient.where('patients.responder_id = patients.id')
          .includes(
            :histories,
            :transfers,
            :laboratories,
            :vaccines,
            :close_contacts,
            :contact_attempts,
            assessments: { reported_condition: :symptoms },
            dependents: [
              :histories,
              :transfers,
              :laboratories,
              :vaccines,
              :close_contacts,
              :contact_attempts,
              { assessments: { reported_condition: :symptoms } }
            ]
          )

      while current_patient_count > desired_patient_count
        patients.find_in_batches(batch_size: 100) do |group|
          break unless current_patient_count > desired_patient_count
          group.each do |patient|
            break unless current_patient_count > desired_patient_count
            current_patient_count -= remove_patient(patient)
            print "\rPatient Count: #{current_patient_count}                   "
          end
        end
      end
    end
    puts 'Done!'
  end

  def remove_patient(patient)
    removed_patients = 1
    ActiveRecord::Base.transaction do
      patient.histories.delete_all
      patient.transfers.delete_all
      patient.laboratories.delete_all
      patient.vaccines.delete_all
      patient.close_contacts.delete_all
      patient.contact_attempts.delete_all
      patient.assessments.each do |assessment|
        assessment.reported_condition&.symptoms&.delete_all
        assessment.reported_condition&.delete
      end
      patient.dependents_exclude_self.each do |dependent|
        removed_patients += remove_patient(dependent)
      end
      patient.delete
    end
    return removed_patients
  end

  ##
  # PATIENT_COUNT=500000 bundle exec rails perf:populate
  #
  # This task is meant to take create a completely new performance database
  # (deleting the existing database completely).
  #
  # ENV:
  #  PATIENT_COUNT (integer) The number of patients to populate in the database.
  #
  desc 'Completely populate the performance database'
  task populate: :environment do
    unless Rails.env.development? || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']
      puts 'bundle exec rails perf:populate'
      raise 'This task is only for use in a development environment'
    end

    puts 'This task will run the following rake tasks:'
    puts '    db:drop'
    puts '    db:create'
    puts '    db:schema:load'
    puts '    admin:import_or_update_jurisdictions'
    puts '    perf:setup_performance_test_users'
    puts '    perf:populate_and_simulate_patients'
    puts"\nDo you wish to continue? (y/N)"
    res =  ENV['APP_IN_CI'].nil? ? STDIN.getc : 'y'
    exit unless res.downcase == 'y'

    ENV['PERFORMANCE'] = 'true'
    ENV['ACCEPT_JURISDICTIONS'] = 'y'
    puts "\n\nExecuting Task: db:drop"
    Rake::Task["db:drop"].invoke
    puts "\n\nExecuting Task: db:create"
    Rake::Task["db:create"].invoke
    puts "\n\nExecuting Task: db:schema:load"
    Rake::Task["db:schema:load"].invoke
    puts "\n\nExecuting Task: admin:import_or_update_jurisdictions"
    Rake::Task["admin:import_or_update_jurisdictions"].invoke
    puts "\n\nExecuting Task: perf:setup_performance_test_users"
    Rake::Task["perf:setup_performance_test_users"].invoke
    puts "\n\nExecuting Task: perf:populate_and_simulate_patients"
    Rake::Task["perf:populate_and_simulate_patients"].invoke
  end

  ##
  # PATIENT_COUNT=500000 bundle exec rails perf:populate_and_simulate_patients
  #
  # This task is meant to populate a database with BOTH demo:populate and
  # demo:create_bulk_data. It will create the number of patients specified in
  # the PATIENT_COUNT environment variable (default 500,000) by creating 10%
  # with demo:populate (up to a max of 30,000) and the remainder with
  # demo:create_bulk_data
  #
  # ENV:
  #  PATIENT_COUNT (integer) The number of patients to populate in the database.
  #
  desc 'Generate patients for performance testing'
  task populate_and_simulate_patients: :environment do
    # Configurable variables
    target_patients = (ENV['PATIENT_COUNT']|| 500_000).to_i
    days = (ENV['DAYS'] || 14).to_i

    # Calculated variables
    num_prototype_patients = [(target_patients * 0.1).to_i, 30_000].min

    ENV['LIMIT'] = num_prototype_patients.to_s
    # Reduce num_prototype_patients here since demo:populate grows new patient count with each day
    ENV['COUNT'] = (ENV['COUNT'] || (num_prototype_patients * 0.85) / days).to_i.to_s
    Rake::Task["demo:populate"].invoke

    ENV['COUNT'] = (target_patients - num_prototype_patients).to_s
    Rake::Task["demo:create_bulk_data"].invoke
  end

  ##
  # bundle exec rails perf:setup_performance_test_users
  #
  # This task is meant to populate users for a very large number of
  # jurisdictions. If the # of jurisdictions if less than 50 or if there are
  # any users in the database, then this will not execute.
  #
  desc 'Configure the users in the database for performance testing'
  task setup_performance_test_users: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env.development? || ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK']

    num_jurisdictions = Jurisdiction.count
    puts "Creating users for #{num_jurisdictions} jurisdictions\n"

    unless num_jurisdictions > 50
      puts ' Jurisdictions were not found! Make sure to run `PERFORMANCE=true bundle exec rake admin:import_or_update_jurisdictions` or `bundle exec rails perf:populate`'
      exit(1)
    end

    num_users = User.count
    unless num_users.zero?
      puts 'This task should only be run when no users exist!'
      puts "There are currently #{num_users} users."
      exit(1)
    end
    users = []

    # Super User at the USA level
    usa = Jurisdiction.find_by_name('USA')
    usa_user = User.create!(
      email: "#{usa.unique_identifier}_super_user@example.com",
      password: '1234567ab!',
      role: Roles::SUPER_USER,
      jurisdiction_id: usa.id,
      force_password_change: false,
      authy_enabled: false,
      authy_enforced: false
    )

    # Create prototype user as hash using to_json and adding in any fields that
    # are non-nil and are not generated from to_json
    prototype_user = usa_user.as_json.symbolize_keys.reject { |k| k == :id || k == :jurisdiction_path }.merge(
      {
        encrypted_password: usa_user[:encrypted_password],
        sign_in_count: usa_user[:sign_in_count],
        failed_attempts: usa_user[:failed_attempts],
        notes: usa_user[:notes]
      }
    )

    Jurisdiction.all.pluck(:id, :unique_identifier).each_with_index do |(id, unique_identifier), index|
      # Create one enroller, admin, public_health, contact_tracer per jurisdiction. Users with these roles are not a large percentage.
      users << create_user(prototype_user, "#{unique_identifier}_enroller@example.com", Roles::ENROLLER, id)
      users << create_user(prototype_user, "#{unique_identifier}_admin@example.com", Roles::ADMIN, id)
      users << create_user(prototype_user, "#{unique_identifier}_epi@example.com", Roles::PUBLIC_HEALTH, id)
      users << create_user(prototype_user, "#{unique_identifier}_contact_tracer@example.com", Roles::CONTACT_TRACER, id)

      # Very few analysts
      users << create_user(prototype_user, "#{unique_identifier}_analyst@example.com", Roles::ANALYST, id) if index % 1 == 10

      # Create 35-times that many public-health enrollers (based on production data)
      35.times do |phe_number|
        users << create_user(prototype_user, "#{unique_identifier}_#{phe_number}_epi_enroller@example.com", Roles::PUBLIC_HEALTH_ENROLLER, id)
      end
    end

    # Import all users
    puts 'Importing all users... '
    User.import users, validate: false

    # Api testing
    OauthApplication.create!(
      name: 'performance-test',
      redirect_uri: 'http://localhost:3000/redirect',
      scopes: 'user/Patient.* user/Observation.read user/QuestionnaireResponse.read',
      uid: 'performance-test-oauth-app-uid',
      secret: 'performance-test-oauth-app-secret'
    ) if OauthApplication.find_by_uid('performance-test-oauth-app-uid').nil?
  end

  def create_user(prototype_user, email, role, jurisdiction_id)
    prototype_user.merge({
      email: email,
      role: role,
      jurisdiction_id: jurisdiction_id
    })
  end
end
