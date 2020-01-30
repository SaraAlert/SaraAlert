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

    count = ENV['COUNT'] || 100

    enroller1 = User.where("email LIKE 'enroller%'").first
    enroller2 = User.where("email LIKE 'enroller%'").last

    assessment_columns = Assessment.column_names - ["id", "created_at", "updated_at", "patient_id", "symptomatic", "temperature"]
    all_false = assessment_columns.each_with_object({}) { |column, hash| hash[column] = false }

    print 'Creating patients...'
    count.times do |i|
      years = rand(80)
      days = rand(365)
      sex = rand < 0.5 ? 'Male' : 'Female'
      Patient.transaction do
        patient = Patient.new(first_name: "Example#{i}", last_name: "Person", sex: sex, date_of_birth: Date.today - years.years - days.days, creator: rand < 0.3 ? enroller1 : enroller2, created_at: rand < 0.7 ? Time.now - 2.days : Time.now)
        patient.responder = patient
        patient.save
        rand(15).times do
          patient.assessments.create({ symptomatic: false, created_at: rand < 0.7 ? Time.now - 2.days : Time.now }.merge(all_false))
        end
        if rand < 0.03
          number_of_symptoms = rand(assessment_columns.size) + 1
          some_true = all_false.dup
          some_true.keys.shuffle[0,number_of_symptoms].each { |key| some_true[key] = true }
          patient.assessments.create({ symptomatic: true }.merge(some_true))
        end
      end
      print '.' if i % 100 == 0
    end
    puts ' done!'
  end

end
