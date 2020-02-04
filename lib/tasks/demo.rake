namespace :demo do

  desc "Configure the database for demo use"
  task setup: :environment do
    print 'Creating enrollers...'
    enroller1 = User.new(email: 'enroller1@example.com', password: '123456')
    enroller1.add_role :enroller
    enroller1.save
    enroller2 = User.new(email: 'enroller2@example.com', password: '123456')
    enroller2.add_role :enroller
    enroller2.save
    puts ' done!'

    print 'Creating epis...'
    epi1 = User.new(email: 'epi1@example.com', password: '123456')
    epi1.add_role :monitor
    epi1.save
    puts ' done!'

    #print 'Creating patients...'
    #patient1 = Patient.new(first_name: 'Example1', last_name: 'Person1', sex: 'Male', dob: Date.today - 44.years - 100.days, creator: enroller1)
    #patient1.responder = patient1
    #patient1.save
    #patient2 = Patient.new(first_name: 'Example2', last_name: 'Person2', sex: 'Female', dob: Date.today - 68.years - 200.days, creator: enroller2)
    #patient2.responder = patient2
    #patient2.save
    #puts ' done!'

    #print 'Creating assessments...'
    #patient1.assessments.create(symptomatic: false)
    #patient1.assessments.create(symptomatic: false)
    #patient1.assessments.create(symptomatic: true)
    #patient2.assessments.create(symptomatic: false)
    #patient2.assessments.create(symptomatic: false)
    #patient2.assessments.create(symptomatic: false)
    #puts ' done!'
  end

  desc "Add lots of data to the database to provide some idea of basic scaling issues"
  task populate: :environment do

    days = (ENV['DAYS'] || 14).to_i
    count = (ENV['COUNT'] || 50).to_i

    enroller1 = User.where("email LIKE 'enroller%'").first
    enroller2 = User.where("email LIKE 'enroller%'").last

    assessment_columns = Assessment.column_names - ["id", "created_at", "updated_at", "patient_id", "symptomatic", "temperature"]
    all_false = assessment_columns.each_with_object({}) { |column, hash| hash[column] = false }
    all_false[:temperature] = '98'

    days.times do |day|

      today = Date.today - (days - (day + 1)).days

      # Create the patients for this day
      print "Creating synthetic patients for day #{day + 1} (#{today})..."

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
            #primary_language
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
            flight_or_vessel_number: "#{('A'..'Z').to_a.shuffle[0]}#{rand(10)}#{rand(10)}#{rand(10)}",
            flight_or_vessel_carrier: "#{Faker::Name.first_name} Airlines",
            port_of_entry_into_usa: Faker::Address.city,
            date_of_arrival: today,
            #travel_related_notes
            last_date_of_potential_exposure: today - rand(5).days,
            potential_exposure_location: Faker::Address.city,
            potential_exposure_country: Faker::Address.country,
            #contact_of_known_case
            #contact_of_known_case_id
            healthcare_worker: rand < 0.1,
            worked_in_health_care_facility: rand < 0.15,
            creator: rand < 0.3 ? enroller1 : enroller2,
            created_at: Faker::Time.between_dates(from: today, to: today, period: :day)
          )

          patient[[:white, :black_or_african_american, :american_indian_or_alaska_native, :asian, :native_hawaiian_or_other_pacific_islander].shuffle.first] = true

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
