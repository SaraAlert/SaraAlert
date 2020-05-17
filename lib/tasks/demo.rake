# frozen_string_literal: true

namespace :demo do
  desc 'Configure the database for demo use'
  task setup: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    #####################################

    print 'Creating jurisdictions...'

    usa = Jurisdiction.where(name: 'USA').first
    state1 = Jurisdiction.where(name: 'State 1').first
    state2 = Jurisdiction.where(name: 'State 2').first
    county1 = Jurisdiction.where(name: 'County 1').first
    county2 = Jurisdiction.where(name: 'County 2').first
    county3 = Jurisdiction.where(name: 'County 3').first
    county4 = Jurisdiction.where(name: 'County 4').first

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    enroller1 = User.new(email: 'state1_enroller@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller1.add_role :enroller
    enroller1.save

    enroller2 = User.new(email: 'localS1C1_enroller@example.com', password: '1234567ab!', jurisdiction: county1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller2.add_role :enroller
    enroller2.save

    enroller3 = User.new(email: 'localS1C2_enroller@example.com', password: '1234567ab!', jurisdiction: county2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller3.add_role :enroller
    enroller3.save

    enroller4 = User.new(email: 'state2_enroller@example.com', password: '1234567ab!', jurisdiction: state2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller4.add_role :enroller
    enroller4.save

    enroller5 = User.new(email: 'localS2C3_enroller@example.com', password: '1234567ab!', jurisdiction: county3, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller5.add_role :enroller
    enroller5.save

    enroller6 = User.new(email: 'localS2C4_enroller@example.com', password: '1234567ab!', jurisdiction: county4, force_password_change: false, authy_enabled: false, authy_enforced: false)
    enroller6.add_role :enroller
    enroller6.save

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    ph1 = User.new(email: 'state1_epi@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph1.add_role :public_health
    ph1.save

    ph2 = User.new(email: 'localS1C1_epi@example.com', password: '1234567ab!', jurisdiction: county1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph2.add_role :public_health
    ph2.save

    ph3 = User.new(email: 'localS1C2_epi@example.com', password: '1234567ab!', jurisdiction: county2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph3.add_role :public_health
    ph3.save

    ph4 = User.new(email: 'state2_epi@example.com', password: '1234567ab!', jurisdiction: state2, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph4.add_role :public_health
    ph4.save

    ph5 = User.new(email: 'localS2C3_epi@example.com', password: '1234567ab!', jurisdiction: county3, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph5.add_role :public_health
    ph5.save

    ph6 = User.new(email: 'localS2C4_epi@example.com', password: '1234567ab!', jurisdiction: county4, force_password_change: false, authy_enabled: false, authy_enforced: false)
    ph6.add_role :public_health
    ph6.save

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    phe1 = User.new(email: 'state1_epi_enroller@example.com', password: '1234567ab!', jurisdiction: state1, force_password_change: false, authy_enabled: false, authy_enforced: false)
    phe1.add_role :public_health_enroller
    phe1.save

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    admin1 = User.new(email: 'admin1@example.com', password: '1234567ab!', jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false)
    admin1.add_role :admin
    admin1.save

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    analyst1 = User.new(email: 'analyst_all@example.com', password: '1234567ab!', jurisdiction: usa, force_password_change: false, authy_enabled: false, authy_enforced: false)
    analyst1.add_role :analyst
    analyst1.save

    puts ' done!'

    #####################################
  end

  desc 'Add lots of data to the database to provide some idea of basic scaling issues'
  task populate: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    days = (ENV['DAYS'] || 14).to_i
    count = (ENV['COUNT'] || 25).to_i
    perform_daily_analytics_update = (ENV['SKIP_ANALYTICS'] != 'true')

    enrollers = User.all.select { |u| u.has_role?('enroller') }
    epis = User.all.select { |u| u.has_role?('public_health') }

    assessment_columns = Assessment.column_names - %w[id created_at updated_at patient_id symptomatic who_reported]
    all_false = assessment_columns.each_with_object({}) { |column, hash| hash[column] = false }

    jurisdictions = Jurisdiction.all
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path).map {|key, value| [key, value]}]
    Analytic.delete_all

    territory_names = ['American Samoa',
      'District of Columbia',
      'Federated States of Micronesia',
      'Guam',
      'Marshall Islands',
      'Northern Mariana Islands',
      'Palau',
      'Puerto Rico',
      'Virgin Islands']

    monitoring_reasons = ['Completed Monitoring',
                          'Meets Case Definition',
                          'Lost to follow-up during monitoring period',
                          'Lost to follow-up (contact never established)',
                          'Transferred to another jurisdiction',
                          'Person Under Investigation (PUI)',
                          'Case confirmed',
                          'Past monitoring period',
                          'Meets criteria to discontinue isolation',
                          'Deceased',
                          'Other']

    days.times do |day|
      today = Date.today - (days - (day + 1)).days
      # Create the patients for this day
      printf("Simulating day #{day + 1} (#{today}):\n")

      # Transactions speeds things up a bit
      ActiveRecord::Base.transaction do
      
        # Patients created before today
        existing_patients = Patient.where('created_at < ?', today)

        # Histories to be created today
        histories = []
      
        # Create assessments for 80-90% of patients on any given day
        printf("Generating assessments...")

        # Get symptoms for each jurisdiction
        unpopulated_conditions = {}
        jurisdictions.each do |jurisdiction|
          unpopulated_conditions[jurisdiction.id] = jurisdiction.hierarchical_condition_unpopulated_symptoms
        end
        
        # Generate unpopulated assessments
        patient_and_jur_ids_assessment = existing_patients.pluck(:id, :jurisdiction_id).sample(existing_patients.count * rand(80..90) / 100)
        patient_and_jur_ids_assessment.each_with_index do |(patient_id, jur_id), index|
          printf("\rGenerating assessment #{index+1} of #{patient_and_jur_ids_assessment.length}...")
          timestamp = Faker::Time.between_dates(from: today, to: today, period: :day)
          reported_condition = unpopulated_conditions[jur_id].dup
          symptoms = []
          unpopulated_conditions[jur_id].symptoms.each do |symptom|
            symptoms.push(symptom.dup)
          end
          reported_condition.symptoms = symptoms
          bool_symps = reported_condition.symptoms.select {|s| s.type == "BoolSymptom" }
          bool_symps.each do |symp| symp['bool_value'] = false end
          assessment = Assessment.new(
            patient_id: patient_id,
            reported_condition: reported_condition,
            symptomatic: false,
            created_at: timestamp,
            updated_at: timestamp
          )
          assessment.save
          if rand < 0.3 # 30% report some sort of symptoms
            number_of_symptoms = rand(bool_symps.count) + 1
            bool_symps.shuffle[0, number_of_symptoms].each do |symp| symp['bool_value'] = true end
            # Outside the context of the demo script, an assessment would already have a threshold condition saved to check the symptomatic status
            # We'll compensate for that here by just re-updating
            assessment.update(symptomatic: assessment.symptomatic?)
            Patient.find(patient_id).refresh_symptom_onset(assessment.id)
          end
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User created a new report.",
            patient_id: patient_id,
            history_type: 'Report Created',
            created_at: timestamp,
            updated_at: timestamp
          )
        end
        printf(" done.\n")

        # Create laboratories for 10-20% of isolation patients on any given day
        printf("Generating laboratories...")
        laboratories = []
        isolation_patients = existing_patients.where(isolation: true)
        patient_ids_lab = isolation_patients.pluck(:id).sample(isolation_patients.count * rand(15..25) / 100)
        patient_ids_lab.each_with_index do |patient_id, index|
          printf("\rGenerating laboratory #{index+1} of #{patient_ids_lab.length}...")
          timestamp = Faker::Time.between_dates(from: today, to: today, period: :day)
          report_date = Faker::Time.between_dates(from: 1.week.ago, to: today, period: :day)
          laboratories << Laboratory.new(
            patient_id: patient_id,
            lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'].sample,
            specimen_collection: Faker::Time.between_dates(from: 2.weeks.ago, to: report_date, period: :day),
            report: report_date,
            result: ['positive', 'negative', 'indeterminate', 'other'].sample,
            created_at: timestamp,
            updated_at: timestamp
          )
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User added a new lab result.",
            patient_id: patient_id,
            history_type: 'Lab Result',
            created_at: timestamp,
            updated_at: timestamp
          )
        end
        Laboratory.import! laboratories
        printf(" done.\n")

        # Create transfers
        printf("Generating transfers...")
        transfers = []
        patient_updates = {}
        patient_and_jur_ids_transfer = existing_patients.pluck(:id, :jurisdiction_id).sample(existing_patients.count * rand(5..15) / 100)
        patient_and_jur_ids_transfer.each_with_index do |(patient_id, jur_id), index|
          printf("\rGenerating transfer #{index+1} of #{patient_and_jur_ids_transfer.length}...")
          timestamp = Faker::Time.between_dates(from: today, to: today, period: :day)
          to_jurisdiction = (jurisdictions.ids - [jur_id]).sample
          patient_updates[patient_id] = { jurisdiction_id: to_jurisdiction }
          transfers << Transfer.new(
            patient_id: patient_id,
            to_jurisdiction_id: to_jurisdiction,
            from_jurisdiction_id: jur_id,
            who_id: epis.sample.id,
            created_at: timestamp,
            updated_at: timestamp
          )
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User changed jurisdiction from \"#{jurisdiction_paths[jur_id]}\" to #{jurisdiction_paths[to_jurisdiction]}.",
            patient_id: patient_id,
            history_type: 'Monitoring Change',
            created_at: timestamp,
            updated_at: timestamp
          )
        end
        Patient.update(patient_updates.keys, patient_updates.values)
        Transfer.import! transfers
        printf(" done.\n")

        # Create count patients
        printf("Generating monitorees...")
        patients = []
        count.times do |i|
          printf("\rGenerating monitoree #{i+1} of #{count}...")
          timestamp = Faker::Time.between_dates(from: today, to: today, period: :day)
          sex = Faker::Gender.binary_type
          birthday = Faker::Date.birthday(min_age: 1, max_age: 85)
          risk_factors = rand < 0.9
          isol = rand < 0.30
          monitoring = rand < 0.95
          patient = Patient.new(
            first_name: "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}",
            middle_name: "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}",
            last_name: "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}",
            sex: rand < 0.9 ? sex : 'Unknown',
            date_of_birth: birthday,
            age: ((Date.today - birthday) / 365.25).round,
            ethnicity: rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino',
            primary_language: 'English',
            address_line_1: Faker::Address.street_address,
            address_city: Faker::Address.city,
            address_state: Faker::Address.state,
            address_line_2: rand < 0.3 ? Faker::Address.secondary_address : nil,
            address_zip: Faker::Address.zip_code,
            primary_telephone: '(333) 333-3333',
            primary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline'].sample,
            secondary_telephone: '(333) 333-3333',
            secondary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline'].sample,
            email: "#{rand(1000000000..9999999999)}fake@example.com",
            preferred_contact_method: ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].sample,
            preferred_contact_time: ['Morning', 'Afternoon', 'Evening', nil].sample,
            port_of_origin: Faker::Address.city,
            date_of_departure: today - (rand < 0.3 ? 1.day : 0.days),
            source_of_report: rand < 0.4 ? 'Self-Identified' : 'CDC',
            flight_or_vessel_number: "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}",
            flight_or_vessel_carrier: "#{Faker::Name.first_name} Airlines",
            port_of_entry_into_usa: Faker::Address.city,
            date_of_arrival: today,
            last_date_of_exposure: today - rand(5).days,
            potential_exposure_location: rand < 0.7 ? Faker::Address.city : nil,
            potential_exposure_country: rand < 0.8 ? Faker::Address.country: nil,
            contact_of_known_case: risk_factors && rand < 0.3,
            travel_to_affected_country_or_area: risk_factors && rand < 0.1,
            was_in_health_care_facility_with_known_cases: risk_factors && rand < 0.15,
            laboratory_personnel: risk_factors && rand < 0.05,
            healthcare_personnel: risk_factors && rand < 0.2,
            crew_on_passenger_or_cargo_flight: risk_factors && rand < 0.25,
            member_of_a_common_exposure_cohort: risk_factors && rand < 0.1,
            creator_id: enrollers.sample.id,
            jurisdiction_id: jurisdictions.sample.id,
            responder_id: 1, # temporarily set responder_id to 1 to pass schema validation
            user_defined_id_statelocal: "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}",
            isolation: isol,
            case_status: isol ? ['Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case'].sample : nil,
            monitoring: monitoring,
            closed_at: monitoring ? nil : today,
            monitoring_reason: monitoring ? nil : monitoring_reasons.sample,
            pause_notifications: rand < 0.1,
            submission_token: SecureRandom.hex(20),
            created_at: timestamp,
            updated_at: timestamp
          )

          patient[%i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander].sample] = true

          if rand < 0.7
            patient[:monitored_address_line_1] = patient[:address_line_1]
            patient[:monitored_address_city] = patient[:address_city]
            patient[:monitored_address_state] = patient[:address_state]
            patient[:monitored_address_line_2] = patient[:address_line_2]
            patient[:monitored_address_zip] = patient[:address_zip]
          else
            patient[:monitored_address_line_1] = Faker::Address.street_address
            patient[:monitored_address_city] = Faker::Address.city
            patient[:monitored_address_state] = rand > 0.5 ? Faker::Address.state : territory_names[rand(territory_names.count)]
            patient[:monitored_address_line_2] = rand < 0.3 ? Faker::Address.secondary_address : nil
            patient[:monitored_address_zip] = Faker::Address.zip_code
          end

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
          end

          patient[:exposure_risk_assessment] = ['High', 'Medium', 'Low', 'No Identified Risk', nil].sample
          patient[:monitoring_plan] = ['Self-monitoring with delegated supervision', 'Daily active monitoring',
                                       'Self-monitoring with public health supervision', 'Self-observation', 'None', nil].sample
          
          if !isol && rand < 0.1
            patient[:public_health_action] = [
              'Recommended medical evaluation of symptoms',
              'Document results of medical evaluation',
              'Recommended laboratory testing'
            ].sample
          end

          patients << patient
        end
        
        Patient.import! patients

        new_patients = Patient.where('created_at >= ?', today)
        new_patients.update_all('responder_id = id')
        new_patients.each do |patient|
          # enrollment
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: 'User enrolled monitoree.',
            patient_id: patient[:id],
            history_type: 'Enrollment',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          )
          # monitoring status
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User changed monitoring status to \"Not Monitoring\". Reason: #{patient[:monitoring_reason]}",
            patient_id: patient[:id],
            history_type: 'Monitoring Change',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          ) unless patient[:monitoring]
          # exposure risk assessment
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User changed exposure risk assessment to \"#{patient[:exposure_risk_assessment]}\".",
            patient_id: patient[:id],
            history_type: 'Monitoring Change',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          ) unless patient[:exposure_risk_assessment].nil?
          # case status
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User changed case status to \"#{patient[:case_status]}\", and chose to \"Continue Monitoring in Isolation Workflow\".",
            patient_id: patient[:id],
            history_type: 'Monitoring Change',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          ) unless patient[:case_status].nil?
          # public health action
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User changed latest public health action to \"#{patient[:public_health_action]}\".",
            patient_id: patient[:id],
            history_type: 'Monitoring Change',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          ) unless patient[:public_health_action] == 'None'
          # pause notifications
          histories << History.new(
            created_by: 'Sara Alert System',
            comment: "User paused notifications for this monitoree.",
            patient_id: patient[:id],
            history_type: 'Monitoring Change',
            created_at: patient[:created_at],
            updated_at: patient[:updated_at],
          ) unless patient[:public_health_action] == 'None'
        end
        printf(" done.\n")

        # Create history events
        printf("Writing histories...")
        History.import! histories
        printf(" done.\n")

        # Run the analytics cache update at the end of each simulation day, or only on final day if SKIP is set.
        printf("Caching analytics...")
        if perform_daily_analytics_update || (day + 1) == days
          Rake::Task["analytics:cache_current_analytics"].reenable
          Rake::Task["analytics:cache_current_analytics"].invoke
          # Add time onto update time for more realistic reports
          t = Time.now
          date_time_update = DateTime.new(today.year, today.month, today.day, t.hour, t.min, t.sec, t.zone)
          Analytic.where('created_at > ?', 1.hour.ago).update_all(created_at: date_time_update, updated_at: date_time_update)
        end
        printf(" done.\n")
      end

      # Cases increase 10-20% every day
      count += (count * (0.1 + (rand / 10))).round
      printf("\n")
    end
  end
end
