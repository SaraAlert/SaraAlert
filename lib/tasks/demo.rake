namespace :demo do

  desc "Configure the database for demo use"
  task setup: :environment do

    raise "This task is only for use in a development environment" unless Rails.env == 'development'

    #####################################

    print 'Creating jurisdictions...'

    usa = Jurisdiction.create(name: 'USA')
    state1 = Jurisdiction.create(name: 'State 1', parent: usa)
    state2 = Jurisdiction.create(name: 'State 2', parent: usa)
    county1 = Jurisdiction.create(name: 'County 1', parent: state1)
    county2 = Jurisdiction.create(name: 'County 2', parent: state1)
    county3 = Jurisdiction.create(name: 'County 3', parent: state2)
    county4 = Jurisdiction.create(name: 'County 4', parent: state2)

    puts ' done!'

    #####################################

    print 'Creating enroller users...'

    enroller1 = User.new(email: 'state1_enroller@example.com', password: '123456ab', jurisdiction: state1, force_password_change: false)
    enroller1.add_role :enroller
    enroller1.save

    enroller2 = User.new(email: 'localS1C1_enroller@example.com', password: '123456ab', jurisdiction: county1, force_password_change: false)
    enroller2.add_role :enroller
    enroller2.save

    enroller3 = User.new(email: 'localS1C2_enroller@example.com', password: '123456ab', jurisdiction: county2, force_password_change: false)
    enroller3.add_role :enroller
    enroller3.save

    enroller4 = User.new(email: 'state2_enroller@example.com', password: '123456ab', jurisdiction: state2, force_password_change: false)
    enroller4.add_role :enroller
    enroller4.save

    enroller5 = User.new(email: 'localS2C3_enroller@example.com', password: '123456ab', jurisdiction: county3, force_password_change: false)
    enroller5.add_role :enroller
    enroller5.save

    enroller6 = User.new(email: 'localS2C4_enroller@example.com', password: '123456ab', jurisdiction: county4, force_password_change: false)
    enroller6.add_role :enroller
    enroller6.save

    puts ' done!'

    #####################################

    print 'Creating public health users...'

    ph1 = User.new(email: 'state1_epi@example.com', password: '123456ab', jurisdiction: state1, force_password_change: false)
    ph1.add_role :public_health
    ph1.save

    ph2 = User.new(email: 'localS1C1_epi@example.com', password: '123456ab', jurisdiction: county1, force_password_change: false)
    ph2.add_role :public_health
    ph2.save

    ph3 = User.new(email: 'localS1C2_epi@example.com', password: '123456ab', jurisdiction: county2, force_password_change: false)
    ph3.add_role :public_health
    ph3.save

    ph4 = User.new(email: 'state2_epi@example.com', password: '123456ab', jurisdiction: state2, force_password_change: false)
    ph4.add_role :public_health
    ph4.save

    ph5 = User.new(email: 'localS2C3_epi@example.com', password: '123456ab', jurisdiction: county3, force_password_change: false)
    ph5.add_role :public_health
    ph5.save

    ph6 = User.new(email: 'localS2C4_epi@example.com', password: '123456ab', jurisdiction: county4, force_password_change: false)
    ph6.add_role :public_health
    ph6.save

    puts ' done!'

    #####################################

    print 'Creating public health enroller users...'

    phe1 = User.new(email: 'state1_epi_enroller@example.com', password: '123456ab', jurisdiction: state1, force_password_change: false)
    phe1.add_role :public_health_enroller
    phe1.save

    puts ' done!'

    #####################################

    print 'Creating admin users...'

    admin1 = User.new(email: 'admin1@example.com', password: '123456ab', jurisdiction: usa, force_password_change: false)
    admin1.add_role :admin
    admin1.save

    puts ' done!'

    #####################################

    print 'Creating analyst users...'

    analyst1 = User.new(email: 'analyst_all@example.com', password: '123456ab', jurisdiction: usa, force_password_change: false)
    analyst1.add_role :analyst
    analyst1.save

    puts ' done!'

    #####################################

  end

  desc "Add lots of data to the database to provide some idea of basic scaling issues"
  task populate: :environment do

    raise "This task is only for use in a development environment" unless Rails.env == 'development'

    days = (ENV['DAYS'] || 14).to_i
    count = (ENV['COUNT'] || 25).to_i

    enrollers = User.all.select { |u| u.has_role?('enroller') }

    assessment_columns = Assessment.column_names - ["id", "created_at", "updated_at", "patient_id", "symptomatic", "temperature", "who_reported"]
    all_false = assessment_columns.each_with_object({}) { |column, hash| hash[column] = false }
    all_false[:temperature] = '98'

    jurisdictions = Jurisdiction.all

    days.times do |day|

      today = Date.today - (days - (day + 1)).days

      # Create the patients for this day
      print "Creating synthetic monitorees for day #{day + 1} (#{today})..."

      # Transaction speeds things up a bit
      Patient.transaction do

        # Any existing patients may or may not report
        Patient.find_each do |patient|
          next unless patient.created_at <= today
          next if patient.confirmed_case
          next if patient.assessments.any? { |a| a.created_at.to_date == today }
          if rand < 0.7 # 70% reporting rate on any given day
            if rand < 0.03 # 3% report some sort of symptoms
              number_of_symptoms = rand(assessment_columns.size) + 1
              some_true = all_false.dup
              some_true.keys.shuffle[0,number_of_symptoms].each { |key| some_true[key] = true }
              some_true[:temperature] = "#{100 + rand(3)}"
              patient.assessments.create({ symptomatic: true, created_at: Faker::Time.between_dates(from: today, to: today, period: :day) }.merge(some_true))
            else
              patient.assessments.create({ symptomatic: false, created_at: Faker::Time.between_dates(from: today, to: today, period: :day) }.merge(all_false))
            end
          end
        end

        # Some proportion of patients who are symptomatic may be confirmed cases
        Patient.find_each do |patient|
          next if patient.confirmed_case
          next unless patient.assessments.order(:created_at).last(3).all?(&:symptomatic)
          if rand < 0.1 # 10% actually become confirmed cases
            patient.update_attributes(confirmed_case: true)
          end
        end

        # Create count patients
        count.times do |i|

          sex = Faker::Gender.binary_type
          birthday = Faker::Date.birthday(min_age: 1, max_age: 85)
          patient = Patient.new(
            first_name: "#{sex == 'Male' ? Faker::Name.male_first_name : Faker::Name.female_first_name}#{rand(10)}#{rand(10)}",
            middle_name: "#{Faker::Name.middle_name}#{rand(10)}#{rand(10)}",
            last_name: "#{Faker::Name.last_name}#{rand(10)}#{rand(10)}",
            sex: sex,
            date_of_birth: birthday,
            age: ((Date.today - birthday) / 365.25).round,
            ethnicity: rand < 0.82 ? 'Not Hispanic or Latino' : 'Hispanic or Latino',
            primary_language: 'English',
            #interpretation_required
            address_line_1: Faker::Address.street_address,
            address_city: Faker::Address.city,
            # TODO: Different portions of app use abbreviation vs full state, need common approach
            address_state: Faker::Address.state_abbr,
            address_line_2: rand < 0.3 ? Faker::Address.secondary_address : nil,
            address_zip: Faker::Address.zip_code,
            #address_county
            #foreign_address_line_1
            #foreign_address_city
            #foreign_address_country
            #foreign_address_line_2
            #foreign_address_zip
            #foreign_address_line_3
            #foreign_address_state
            #foreign_monitored_address_line_1
            #foreign_monitored_address_city
            #foreign_monitored_address_state
            #foreign_monitored_address_line_2
            #foreign_monitored_address_zip
            #foreign_monitored_address_county
            primary_telephone: '(333) 333-3333',
            primary_telephone_type: rand < 0.7 ? 'Smartphone' : 'Plain Cell',
            secondary_telephone: '(333) 333-3333',
            secondary_telephone_type: 'Landline',
            email: Faker::Internet.email,
            preferred_contact_method: rand < 0.65 ? 'E-mail' : 'Telephone call',
            port_of_origin: Faker::Address.city,
            date_of_departure: today - (rand < 0.3 ? 1.day : 0.days),
            source_of_report: rand < 0.4 ? 'Self-Identified' : 'CDC',
            flight_or_vessel_number: "#{('A'..'Z').to_a.sample}#{rand(10)}#{rand(10)}#{rand(10)}",
            flight_or_vessel_carrier: "#{Faker::Name.first_name} Airlines",
            port_of_entry_into_usa: Faker::Address.city,
            date_of_arrival: today,
            #travel_related_notes
            last_date_of_exposure: today - rand(5).days,
            potential_exposure_location: Faker::Address.city,
            potential_exposure_country: Faker::Address.country,
            #contact_of_known_case
            #contact_of_known_case_id
            travel_to_affected_country_or_area: rand < 0.1,
            was_in_health_care_facility_with_known_cases: rand < 0.15,
            creator: enrollers.sample,
            user_defined_id_statelocal: "EX-#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}#{rand(10)}",
            created_at: Faker::Time.between_dates(from: today, to: today, period: :day)
          )

          patient.submission_token = SecureRandom.hex(20)

          patient[[:white, :black_or_african_american, :american_indian_or_alaska_native, :asian, :native_hawaiian_or_other_pacific_islander].sample] = true

          if rand < 0.7
            patient.monitored_address_line_1 = patient.address_line_1
            patient.monitored_address_city = patient.address_city
            patient.monitored_address_state = patient.address_state
            patient.monitored_address_line_2 = patient.address_line_2
            patient.monitored_address_zip = patient.address_zip
          else
            patient.monitored_address_line_1 = Faker::Address.street_address
            patient.monitored_address_city = Faker::Address.city
            patient.monitored_address_state = Faker::Address.state_abbr
            patient.monitored_address_line_2 = rand < 0.3 ? Faker::Address.secondary_address : nil
            patient.monitored_address_zip = Faker::Address.zip_code
          end

          if rand < 0.3
            patient.additional_planned_travel_type = rand < 0.7 ? 'Domestic' : 'International'
            patient.additional_planned_travel_destination = Faker::Address.city
            patient.additional_planned_travel_destination_state = Faker::Address.city if patient.additional_planned_travel_type == 'Domestic'
            patient.additional_planned_travel_destination_country = Faker::Address.country if patient.additional_planned_travel_type == 'International'
            patient.additional_planned_travel_port_of_departure = Faker::Address.city
            patient.additional_planned_travel_start_date = today + rand(6).days
            patient.additional_planned_travel_end_date = patient.additional_planned_travel_start_date + rand(10).days
            #patient.additional_planned_travel_related_notes
          end

          patient.jurisdiction = jurisdictions.sample
          patient.responder = patient
          patient.save

          print '.' if i % 100 == 0
        end

        # Cases increase 10-20% every day
        count += (count * (0.1 + (rand / 10))).round
      end

      puts ' done!'
    end
  end

end
