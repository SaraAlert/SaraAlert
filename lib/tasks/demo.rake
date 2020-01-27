namespace :demo do
  desc "Configure the database for demo use"
  task setup: :environment do
    print 'Creating patient...'
    patient = Patient.new(first_name: 'Example', last_name: 'Person')
    patient.responder = patient
    patient.save
    puts ' done!'
    print 'Creating assessments...'
    patient.assessments.create(status: 'asymptomatic')
    patient.assessments.create(status: 'asymptomatic')
    patient.assessments.create(status: 'symptomatic')
    puts ' done!'
  end
end
