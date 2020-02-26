namespace :admiin do
    
    desc "Set Symptoms List"
    task add: :environment do
        raise "This task is only for use in a development environment" unless Rails.env == 'development'

        temperature_symptom = FloatSymptom.new(label: 'Temperature', name: 'temperature', float_value: 101.4)
        cough_symptom = BoolSymptom.new(label: 'Cough', name: 'cough', bool_value: true)
        difficulty_breathing_symptom = BoolSymptom.new(label: 'Difficulty Breathing', name: 'difficulty_breathing', bool_value: true)

        usa_condition = Condition.create(symptoms: [temperature_symptom, cough_symptom, difficulty_breathing_symptom])

        usa = Jurisdiction.where(name: 'USA').first
        usa.symptomatic_definitions.push(usa_condition)
        usa.save


        state1 = Jurisdiction.where(name: 'State 1').first
        ate_shellfish = BoolSymptom.new(label: 'Ate Shellfish', name: 'ate_shellfish', bool_value: true)
        state_condition = Condition.create(symptoms: [ate_shellfish])
        state1.symptomatic_definitions.push(state_condition)
        state1.save

    end
end